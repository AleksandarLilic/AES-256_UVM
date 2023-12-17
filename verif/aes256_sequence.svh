import uvm_pkg::*;
//`include "aes256_seq_item.svh"

class aes256_seq_item extends uvm_sequence_item;
    bit key_expand_start;
    rand bit [255:0] master_key;
    bit next_val_req;
    rand bit [127:0] data_in;
    // TODO: implement random period timeout after previous key is ready
    // and loading block started sending ciphertext blocks
    // TODO: implement random pulse length for key_expand_start and next_val_req
    
    `uvm_object_utils_begin(aes256_seq_item)
        `uvm_field_int(key_expand_start, UVM_DEFAULT)
        `uvm_field_int(master_key, UVM_DEFAULT)
        `uvm_field_int(next_val_req, UVM_DEFAULT)
        `uvm_field_int(data_in, UVM_DEFAULT)
    `uvm_object_utils_end

    //constraint c_master_key { master_key >= 0; master_key <= 2048; }
    //constraint c_data_in { data_in >= 0; data_in <= 1024; }
    
    function new (string name = "aes256_seq_item");
        super.new(name);
    endfunction

endclass: aes256_seq_item

class aes256_sequence extends uvm_sequence #(aes256_seq_item);
    rand int number_of_keys;
    rand int number_of_plaintexts;

    `uvm_object_utils_begin(aes256_sequence)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint c_number_of_keys { number_of_keys == 1; }
    constraint c_number_of_plaintexts { number_of_plaintexts == 2; }

    function new (string name = "aes256_sequence");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        int i;
        int j;
        number_of_keys = 1;
        number_of_plaintexts = 2;

        `uvm_info(get_type_name(), "body started", UVM_LOW)
        for (i = 0; i < number_of_keys; i++) begin
            `uvm_info(get_type_name(), $sformatf("key %0d", i), UVM_LOW)
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", i, j));
            item.key_expand_start = 1;
            item.next_val_req = 0;
            start_item(item);
            assert(item.randomize());
            finish_item(item);
            for (j = 0; j < number_of_plaintexts; j++) begin
                item.key_expand_start = 0;
                item.next_val_req = 1;
                start_item(item);
                assert(item.randomize());
                finish_item(item);
            end
        end
    endtask: body

endclass: aes256_sequence
    