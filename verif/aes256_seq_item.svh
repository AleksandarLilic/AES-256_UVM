import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_seq_item extends uvm_sequence_item;
    // design inputs
    bit key_expand_start = 0;
    rand bit [`MATRIX_KEY_WIDTH-1:0] master_key = 0;
    bit next_val_req = 0;
    rand bit [`MATRIX_DATA_WIDTH-1:0] data_in = 0;
    // design outputs
    bit next_val_ready;
    bit [15:0] [7:0] data_out;
    `ifdef HIER_ACCESS
    bit [0:`N_ROUNDS-1] [`MATRIX_ROUND_KEY_WIDTH-1:0] key_exp_round_keys;
    `endif
    `ifdef VIVADO_RND_WORKAROUND
    sweep_type_t sweep_type;
    `endif
    // timing relationships
    rand byte unsigned key_expand_start_pulse;
    rand byte unsigned key_expand_start_delay;
    rand byte unsigned next_val_req_pulse;
    rand byte unsigned next_val_req_delay;
    bool_t wait_for_key_ready = TRUE;
    bool_t wait_for_enc_done = TRUE;
    bool_t key_exp_wait_for_loading_end = TRUE;
    
    `uvm_object_utils_begin(aes256_seq_item)
        // design inputs
        `uvm_field_int(key_expand_start, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(master_key, UVM_DEFAULT)
        `uvm_field_int(next_val_req, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(data_in, UVM_DEFAULT)
        // design outputs
        `uvm_field_int(next_val_ready, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(data_out, UVM_DEFAULT)
        // timing relationships
        `uvm_field_int(key_expand_start_pulse, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_int(key_expand_start_delay, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_int(next_val_req_pulse, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_int(next_val_req_delay, UVM_DEFAULT | UVM_UNSIGNED)
        `uvm_field_enum(bool_t, wait_for_key_ready, UVM_DEFAULT)
        `uvm_field_enum(bool_t, wait_for_enc_done, UVM_DEFAULT)
        `uvm_field_enum(bool_t, key_exp_wait_for_loading_end, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint c_key_expand_start_delay { key_expand_start_delay inside { [0:32] }; }
    constraint c_key_expand_start_pulse { soft key_expand_start_pulse inside { [1:8] }; }
    constraint c_next_val_req_delay { next_val_req_delay inside { [0:2*LOADING_CYCLES] }; }
    constraint c_next_val_req_pulse { soft next_val_req_pulse inside { [1:8] }; }
    
    function new (string name = "aes256_seq_item");
        super.new(name);
    endfunction

    `ifdef VIVADO_RND_WORKAROUND
    function void post_randomize();
        if (sweep_type == SWEEP_TYPE_NONE) begin
            bit [23:0] data_in_fix;
            bit [23:0] master_key_fix_1;
            bit [23:0] master_key_fix_2;
            int unsigned i = 0;
            super.post_randomize();
            data_in_fix = $urandom_range('hFF_FFFF, 0);
            master_key_fix_1 = $urandom_range('hFF_FFFF, 0);
            master_key_fix_2 = $urandom_range('hFF_FFFF, 0);
            for (i = 0; i < 4; i = i + 1)  begin
                data_in[i*32+30 -: 2] = data_in_fix[i*3+2 -: 2];
                master_key[i*32+30 -: 2] = master_key_fix_1[i*3+2 -: 2];
                master_key[128+i*32+30 -: 2] = master_key_fix_2[i*3+2 -: 2];
            end
        end
    endfunction
    `endif

    `ifdef HIER_ACCESS
    // to avoid registering the whole array of round keys
    // but copy has to be implemented separately for round keys
    virtual function void do_copy(uvm_object rhs);
        aes256_seq_item rhs_cast;
        super.do_copy(rhs);
        if (!$cast(rhs_cast, rhs)) `uvm_fatal(get_type_name(), "Cast failed")
        this.key_exp_round_keys = rhs_cast.key_exp_round_keys;
    endfunction
    `endif

endclass: aes256_seq_item
