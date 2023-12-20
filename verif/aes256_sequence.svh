import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_sequence extends uvm_sequence#(aes256_seq_item);
    rand int number_of_keys = 1;
    rand int number_of_plaintexts = 2;

    `uvm_object_utils_begin(aes256_sequence)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    function new (string name = "aes256_sequence");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        int key_cnt;
        int pt_cnt;

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
                // add wait period for the last encryption of the last key
                if (pt_cnt == number_of_plaintexts - 1 && key_cnt == number_of_keys - 1)
                    item.wait_after_enc = 4;                    
                `SEND_ITEM_RAND(item);
            end
        end
    endtask: body

endclass: aes256_sequence
