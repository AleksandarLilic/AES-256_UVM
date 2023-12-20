import uvm_pkg::*;

class aes256_seq_item extends uvm_sequence_item;
    const byte unsigned LOADING_PERIODS = 8;
    // design I/O
    bit key_expand_start = 0;
    rand bit [255:0] master_key = 0;
    bit next_val_req = 0;
    rand bit [127:0] data_in = 0;
    // timing relationships
    rand byte unsigned key_expand_start_pulse;
    rand byte unsigned key_expand_start_delay;
    rand byte unsigned next_val_req_pulse;
    rand byte unsigned next_val_req_delay;
    byte unsigned wait_at_the_end = 0;
    rand bit wait_for_key_ready = 1;
    
    `uvm_object_utils_begin(aes256_seq_item)
        `uvm_field_int(key_expand_start, UVM_DEFAULT)
        `uvm_field_int(master_key, UVM_DEFAULT)
        `uvm_field_int(next_val_req, UVM_DEFAULT)
        `uvm_field_int(data_in, UVM_DEFAULT)
        `uvm_field_int(key_expand_start_pulse, UVM_DEFAULT)
        `uvm_field_int(key_expand_start_delay, UVM_DEFAULT)
        `uvm_field_int(next_val_req_pulse, UVM_DEFAULT)
        `uvm_field_int(next_val_req_delay, UVM_DEFAULT)
        `uvm_field_int(wait_at_the_end, UVM_DEFAULT)
        `uvm_field_int(wait_for_key_ready, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint c_key_expand_start_delay {
        key_expand_start_delay >= 0;
        key_expand_start_delay <= 50;
    }
    constraint c_key_expand_start_pulse {
        key_expand_start_pulse >= 1;
        key_expand_start_pulse <= 10;
    }
    constraint c_next_val_req_delay {
        next_val_req_delay >= 0;
        next_val_req_delay <= 2*LOADING_PERIODS;
    }
    constraint c_next_val_req_pulse {
        next_val_req_pulse >= 1;
        next_val_req_pulse <= 10;
    }
    
    function new (string name = "aes256_seq_item");
        super.new(name);
    endfunction

endclass: aes256_seq_item
