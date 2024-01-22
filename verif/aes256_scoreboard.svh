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
    byte unsigned key_bytes[32];
    byte unsigned plaintext_bytes[16];
    byte unsigned round_keys_bytes[240];
    byte unsigned ciphertext_bytes[16];
    bit [127:0] model_data_out;
    bit [0:14] [127:0] model_round_keys;
    int unsigned error_count = 0;
    bool_t use_ref_vectors = FALSE;
    integer fd_vector;
    string line;
    bit [255:0] ref_master_key;
    bit [127:0] ref_data_in;
    bit [127:0] ref_data_out;

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
            `uvm_error(get_type_name(), $sformatf("Model checker FAILED. Key expansion mismatch"))
            for (int i = 0; i < 15; i++) begin
                if (model_round_keys[i] != item.key_exp_round_keys[i])
                    `uvm_info(get_type_name(), $sformatf("Round key %2d: expected 'h%32h, received 'h%32h", i, model_round_keys[i], item.key_exp_round_keys[i]), UVM_NONE)
            end
            error_count += 1;
        end
        `endif

        assert (model_data_out == item.data_out) else begin
            `uvm_error(get_type_name(), $sformatf("Model checker FAILED. Ciphertext mismatch: expected 'h%0h, received 'h%0h", model_data_out, item.data_out))
            `uvm_info(get_type_name(), $sformatf("Entire packet:\n%s", item.sprint()), UVM_NONE)
            error_count += 1;
        end

        if (use_ref_vectors == TRUE) begin
            if (!$feof(fd_vector)) begin
                void'($fgets(line, fd_vector));
                $sscanf(line, "%h,%h,%h", ref_master_key, ref_data_in, ref_data_out);
                assert (ref_master_key == item.master_key) else begin
                    `uvm_error(get_type_name(), $sformatf("Vector checker input FAILED. Master key mismatch: expected 'h%0h, received 'h%0h", ref_master_key, item.master_key))
                    error_count += 1;
                end
                assert (ref_data_in == item.data_in) else begin
                    `uvm_error(get_type_name(), $sformatf("Vector checker input FAILED. Plaintext mismatch: expected 'h%0h, received 'h%0h", ref_data_in, item.data_in))
                    error_count += 1;
                end
                assert (ref_data_out == item.data_out) else begin
                    `uvm_error(get_type_name(), $sformatf("Vector checker output FAILED. Ciphertext mismatch: expected 'h%0h, received 'h%0h", ref_data_out, item.data_out))
                    error_count += 1;
                end
            end else begin
                `uvm_error(get_type_name(), "Vector checker FAILED. End of reference vectors file reached but more items expected")
                error_count += 1;
            end
        end

        // UVM is compiled with NO_DPI so can't use +UVM_MAX_QUIT_COUNT=1
        // workaround: use $finish and $plusargs to specify before simulation starts
        if (error_count > 0 && $test$plusargs("EXIT_ON_ERROR")) $finish();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Number of items received: %0d", num_items), UVM_NONE)
        if (num_items == 0) begin
            `uvm_warning(get_type_name(), "No items received. Check the test and sequence")
        end else if (error_count == 0) begin
            `uvm_info(get_type_name(), "\n\n==== PASS ====\n\n", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), $sformatf("Total number of errors: %0d", error_count), UVM_NONE)
            `uvm_fatal(get_type_name(), "\n\n==== FAIL ====\n\n")
        end
    endfunction
    
endclass
