import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_sequence_sweep extends uvm_sequence#(aes256_seq_item);
    sweep_type_t sweep_type;
    local int unsigned number_of_keys;
    local int unsigned number_of_plaintexts;
    local byte unsigned wait_period_at_the_end = 10;

    `uvm_object_utils_begin(aes256_sequence_sweep)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    function new (string name = "aes256_sequence_sweep");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        bit [255:0] master_key_sweep = 'h0;
        bit [127:0] data_in_sweep = 'h0;
        int unsigned key_cnt = 0;
        int unsigned pt_cnt = 0;
        
        if (sweep_type == SWEEP_TYPE_KEY) begin
            number_of_keys = $size(master_key_sweep)*2;
            number_of_plaintexts = 1;
            
            for (key_cnt = 0; key_cnt < number_of_keys; key_cnt++) begin
                master_key_sweep[key_cnt % $size(master_key_sweep)] = key_cnt < number_of_keys/2;
                item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));

                `uvm_info(get_type_name(), $sformatf(" ===> New Master Key. Count: %0d <===", key_cnt), UVM_MEDIUM)
                `ifdef VIVADO_RND_WORKAROUND
                item.sweep_type = sweep_type;
                `endif
                item.key_expand_start = 1;
                item.next_val_req = 0;
                item.key_expand_start_delay = 1;
                item.key_expand_start_pulse = 1;
                item.master_key = master_key_sweep;
                `SEND_ITEM(item, 0);
    
                `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext. Count: %0d <===", pt_cnt), UVM_MEDIUM)
                item.key_expand_start = 0;
                item.next_val_req = 1;
                item.next_val_req_delay = 1;
                item.next_val_req_pulse = 1;
                item.data_in = data_in_sweep;
                `SEND_ITEM(item, 0);
            end

        end else if (sweep_type == SWEEP_TYPE_PT) begin
            number_of_keys = 1;
            number_of_plaintexts = $size(data_in_sweep)*2;
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            
            `uvm_info(get_type_name(), $sformatf(" ===> New Master Key. Count: %0d <===", key_cnt), UVM_MEDIUM)
            `ifdef VIVADO_RND_WORKAROUND
            item.sweep_type = sweep_type;
            `endif
            item.key_expand_start = 1;
            item.next_val_req = 0;
            item.key_expand_start_delay = 1;
            item.key_expand_start_pulse = 1;
            item.master_key = master_key_sweep;
            `SEND_ITEM(item, 0);

            for (pt_cnt = 0; pt_cnt < number_of_plaintexts; pt_cnt++) begin
                data_in_sweep[pt_cnt % $size(data_in_sweep)] = pt_cnt < number_of_plaintexts/2;
                `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext. Count: %0d <===", pt_cnt), UVM_MEDIUM)
                item.key_expand_start = 0;
                item.next_val_req = 1;
                item.next_val_req_delay = 1;
                item.next_val_req_pulse = 1;
                item.data_in = data_in_sweep;
                `SEND_ITEM(item, 0);               
            end

        end else begin
            `uvm_fatal(get_type_name(), "Unknown sweep type")
        end
        
        item.key_expand_start = 0;
        item.next_val_req = 0;
        repeat (wait_period_at_the_end) begin
            `SEND_ITEM(item, 0);
        end

    endtask: body

endclass: aes256_sequence_sweep
