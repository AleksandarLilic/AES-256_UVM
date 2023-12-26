import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_seq_item extends uvm_sequence_item;
    // design inputs
    bit key_expand_start = 0;
    rand bit [255:0] master_key = 0;
    bit next_val_req = 0;
    rand bit [127:0] data_in = 0;
    // design outputs
    bit next_val_ready;
    bit [15:0] [7:0] data_out;
    // timing relationships
    rand byte unsigned key_expand_start_pulse;
    rand byte unsigned key_expand_start_delay;
    rand byte unsigned next_val_req_pulse;
    rand byte unsigned next_val_req_delay;
    bool_t wait_for_key_ready = TRUE;
    bool_t wait_for_enc_done = TRUE;
    
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
    `uvm_object_utils_end

    constraint c_key_expand_start_delay { key_expand_start_delay inside { [0:32] }; }
    constraint c_key_expand_start_pulse { key_expand_start_pulse inside { [1:8] }; }
    constraint c_next_val_req_delay { next_val_req_delay inside { [0:2*LOADING_CYCLES] }; }
    constraint c_next_val_req_pulse { next_val_req_pulse inside { [1:8] }; }
    
    function new (string name = "aes256_seq_item");
        super.new(name);
    endfunction

endclass: aes256_seq_item
