import uvm_pkg::*;
`include "aes256_inc.svh"

import "DPI-C" function void aes_dpi(input byte unsigned key[32],
                                     input byte unsigned plaintext[16],
                                     output byte unsigned round_keys[240],
                                     output byte unsigned ciphertext[16]);

class aes256_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(aes256_scoreboard)
    uvm_analysis_imp#(aes256_seq_item, aes256_scoreboard) item_imp;
    
    int unsigned num_items = 0;
    int unsigned num_expected_items = 0;
    bool_t ref_vector_length_mismatch = FALSE;
    byte unsigned key_bytes[32];
    byte unsigned plaintext_bytes[16];
    byte unsigned round_keys_bytes[240];
    byte unsigned ciphertext_bytes[16];
    bit [`MATRIX_DATA_WIDTH-1:0] model_data_out;
    bit [0:`N_ROUNDS-1] [`MATRIX_ROUND_KEY_WIDTH-1:0] model_round_keys;
    int unsigned error_count = 0;
    bool_t use_ref_vectors = FALSE;
    integer fd_vector;
    string line;
    bit [`MATRIX_KEY_WIDTH-1:0] ref_master_key;
    bit [`MATRIX_DATA_WIDTH-1:0] ref_data_in;
    bit [`MATRIX_DATA_WIDTH-1:0] ref_data_out;
    string ref_data_out_str;
    int unsigned mct_pt_cnt = 0;
    bit [`MATRIX_KEY_WIDTH-1:0] DUT_master_key;
    bit [`MATRIX_DATA_WIDTH-1:0] DUT_data_in;

    function new(string name = "aes256_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_imp = new("item_imp", this);
    endfunction

    function write(aes256_seq_item item);
        `uvm_info(get_type_name(), $sformatf("Received item\n%s", item.sprint()), UVM_HIGH)
        num_items++;

        // format sequence item data as byte arrays
        for (int i = 0; i < 32; i++) key_bytes[i] = item.master_key[(31-i)*8 +: 8];
        for (int i = 0; i < 16; i++) plaintext_bytes[i] = item.data_in[(15-i)*8 +: 8];
        
        // run model
        aes_dpi(key_bytes, plaintext_bytes, round_keys_bytes, ciphertext_bytes);
        for (int i = 0; i < 16; i++) model_data_out[i*8 +: 8] = ciphertext_bytes[15-i];
        
        `ifdef HIER_ACCESS
        for (int i = 0; i < 15; i++) begin
            for (int j = 0; j < 16; j++) begin
                model_round_keys[i][j*8 +: 8] = round_keys_bytes[i*16 + 15-j];
            end
        end
        `endif
        
        // compare results
        `ifdef HIER_ACCESS
        assert (model_round_keys == item.key_exp_round_keys) else begin
            `PRINT_SCBD_ERROR($sformatf("Model checker FAILED. Key expansion mismatch"))
            for (int i = 0; i < 15; i++) begin
                if (model_round_keys[i] != item.key_exp_round_keys[i])
                    `uvm_info(get_type_name(), $sformatf("Round key %2d: expected 'h%32h, received 'h%32h", i, model_round_keys[i], item.key_exp_round_keys[i]), UVM_NONE)
            end
            error_count += 1;
        end
        `endif

        assert (model_data_out == item.data_out) else begin
            `PRINT_SCBD_ERROR($sformatf("Model checker FAILED. Ciphertext mismatch: expected 'h%0h, received 'h%0h", model_data_out, item.data_out))
            error_count += 1;
        end

        if (use_ref_vectors == TRUE) begin
            if ($test$plusargs("MCT_VECTORS")) mct_pt_cnt++;
            if ($test$plusargs("MCT_VECTORS") && mct_pt_cnt == 1) begin
                // store key and PT that started MCT
                DUT_master_key = item.master_key;
                DUT_data_in = item.data_in;
            end
            
            // compare last output of MCT or all outputs of non-MCT
            if (($test$plusargs("MCT_VECTORS") && mct_pt_cnt == 1000) || (!$test$plusargs("MCT_VECTORS"))) begin
                if (!$feof(fd_vector)) begin
                    void'($fgets(line, fd_vector));
                    // can't convert str to 128-bit value with str.atohex() as it returns 32-bit value
                    $sscanf(line, "%h,%h,%s", ref_master_key, ref_data_in, ref_data_out_str);
                    $sscanf(line, "%h,%h,%h", ref_master_key, ref_data_in, ref_data_out);

                    if (!$test$plusargs("MCT_VECTORS")) begin
                        DUT_master_key = item.master_key;
                        DUT_data_in = item.data_in;
                    end
                    
                    assert (ref_master_key == DUT_master_key) else begin
                        `PRINT_SCBD_ERROR($sformatf("Vector checker input FAILED. Master key mismatch: expected 'h%0h, received 'h%0h", ref_master_key, item.master_key))
                        error_count += 1;
                    end

                    assert (ref_data_in == DUT_data_in) else begin
                        `PRINT_SCBD_ERROR($sformatf("Vector checker input FAILED. Plaintext mismatch: expected 'h%0h, received 'h%0h", ref_data_in, item.data_in))
                        error_count += 1;
                    end

                    if ($test$plusargs("ALLOW_VECTOR_CHECKER_NONE") && ref_data_out_str == "NONE") begin
                        `uvm_info(get_type_name(), "Vector checker output: no output expected", UVM_HIGH)
                    end else if (ref_data_out_str == "NONE") begin
                        `uvm_error(get_type_name(), "Vector checker output: NONE specified for ciphertext but +ALLOW_VECTOR_CHECKER_NONE not specified. Can't compare outputs")
                        error_count += 1;
                    end else begin
                        assert (ref_data_out == item.data_out) else begin
                            `PRINT_SCBD_ERROR($sformatf("Vector checker output FAILED. Ciphertext mismatch: expected 'h%0h, received 'h%0h", ref_data_out, item.data_out))
                            error_count += 1;
                        end
                    end

                    if ($test$plusargs("MCT_VECTORS")) mct_pt_cnt = 0;

                end else begin
                    `uvm_error(get_type_name(), "Vector checker FAILED. End of reference vectors file reached but more items expected")
                    ref_vector_length_mismatch = TRUE;
                    error_count += 1;
                end
            end
        end

        // UVM is compiled with NO_DPI so can't use +UVM_MAX_QUIT_COUNT=1
        // workaround: use $finish and $plusargs to specify exit on error before simulation start
        if (error_count > 0 && $test$plusargs("EXIT_ON_ERROR")) begin
            `uvm_fatal(get_type_name(), "\n\n==== FAIL ====\n\n")
            $finish();
        end
    endfunction

    function void report_phase(uvm_phase phase);
        bool_t no_erros = bool_t'(error_count == 0);
        bool_t items_cnt_match;
        `uvm_info(get_type_name(), $sformatf("Number of items received: %0d", num_items), UVM_NONE)
        if (!use_ref_vectors) begin
            items_cnt_match = bool_t'(num_items == num_expected_items);
            `uvm_info(get_type_name(), $sformatf("Number of expected items: %0d", num_expected_items), UVM_NONE)
        end else begin
            items_cnt_match = bool_t'(ref_vector_length_mismatch == FALSE);
        end
        
        if (no_erros && items_cnt_match) begin
            `uvm_info(get_type_name(), "\n\n==== PASS ====\n\n", UVM_NONE)
        end else begin
            if (!items_cnt_match) begin
                if (use_ref_vectors) `uvm_error(get_type_name(), "Number of items received does not match number of expected items from the reference vectors file")
                else `uvm_error(get_type_name(), $sformatf("Number of items received (%0d) does not match number of expected items (%0d)", num_items, num_expected_items))
            end else begin
                `uvm_error(get_type_name(), $sformatf("Total number of errors: %0d", error_count))
            end
            `uvm_fatal(get_type_name(), "\n\n==== FAIL ====\n\n")
        end
    endfunction
    
endclass
