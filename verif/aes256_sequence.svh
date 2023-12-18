import uvm_pkg::*;
//`include "aes256_seq_item.svh"

`define SEND_ITEM_RAND(item) \
    start_item(item); \
    assert(item.randomize()); \
    `uvm_info(get_type_name(), $sformatf("\n%s", item.sprint()), UVM_MEDIUM); \
    finish_item(item);

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
    `uvm_object_utils_end

    constraint c_key_expand_start_delay { key_expand_start_delay >= 0; key_expand_start_delay <= 10; }
    constraint c_key_expand_start_pulse { key_expand_start_pulse >= 1; key_expand_start_pulse <= 10; }
    constraint c_next_val_req_delay { next_val_req_delay >= 0; next_val_req_delay <= 2*LOADING_PERIODS; }
    constraint c_next_val_req_pulse { next_val_req_pulse >= 1; next_val_req_pulse <= 10; }
    
    function new (string name = "aes256_seq_item");
        super.new(name);
    endfunction

endclass: aes256_seq_item

class aes256_sequence extends uvm_sequence#(aes256_seq_item);
    rand int number_of_keys;
    rand int number_of_plaintexts;

    `uvm_object_utils_begin(aes256_sequence)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    //constraint c_number_of_keys { number_of_keys == 1; }
    //constraint c_number_of_plaintexts { number_of_plaintexts == 2; }

    function new (string name = "aes256_sequence");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        int key_cnt;
        int pt_cnt;
        number_of_keys = 2;
        number_of_plaintexts = 10;

        for (key_cnt = 0; key_cnt < number_of_keys; key_cnt++) begin
            `uvm_info(get_type_name(), $sformatf("key counter: %0d", key_cnt), UVM_LOW)
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            item.key_expand_start = 1;
            item.next_val_req = 0;
            `SEND_ITEM_RAND(item);
            for (pt_cnt = 0; pt_cnt < number_of_plaintexts; pt_cnt++) begin
                `uvm_info(get_type_name(), $sformatf("plaintext counter: %0d", pt_cnt), UVM_LOW)
                item.key_expand_start = 0;
                item.next_val_req = 1;
                if (pt_cnt == number_of_plaintexts - 1 && key_cnt == number_of_keys - 1)
                    item.wait_at_the_end = 4;                    
                `SEND_ITEM_RAND(item);
            end
        end
    endtask: body

endclass: aes256_sequence
    