import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_sequence extends uvm_sequence#(aes256_seq_item);
    rand int number_of_keys = 1;
    rand int number_of_plaintexts = 2;
    rand bool_t wait_for_key_ready = TRUE; // TODO: this should be used for coverage to hit every state of key expansion FSM to get to idle from every state;
    // TODO: implement similar wait for the encryption FSM
    rand byte unsigned wait_period_at_the_end = 10;

    `uvm_object_utils_begin(aes256_sequence)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint c_number_of_keys {
        number_of_keys >= 1;
    }

    function new (string name = "aes256_sequence");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        int key_cnt = 0;
        int pt_cnt = 0;

        for (key_cnt = 0; key_cnt < number_of_keys; key_cnt++) begin
            `uvm_info(get_type_name(), $sformatf("Master Key counter: %0d", key_cnt), UVM_MEDIUM)
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            item.key_expand_start = 1;
            item.next_val_req = 0;
            `SEND_ITEM_RAND_WITH(item, {wait_for_key_ready == this.wait_for_key_ready;
                                        key_expand_start_delay >= 10; })
            
            for (pt_cnt = 0; pt_cnt < number_of_plaintexts; pt_cnt++) begin
                `uvm_info(get_type_name(), $sformatf("Plaintext counter: %0d", pt_cnt), UVM_MEDIUM)
                item.key_expand_start = 0;
                item.next_val_req = 1;
                // pipleline the requests with no delay
                `SEND_ITEM_RAND_WITH(item, {next_val_req_delay == 1; })
            end
        end
        
        item.key_expand_start = 0;
        item.next_val_req = 0;
        repeat (wait_period_at_the_end) begin
            `SEND_ITEM(item, 0);
        end

    endtask: body

endclass: aes256_sequence
