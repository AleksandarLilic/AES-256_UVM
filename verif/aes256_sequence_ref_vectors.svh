import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_sequence_ref_vectors extends uvm_sequence#(aes256_seq_item);
    `uvm_object_utils(aes256_sequence_ref_vectors)
    byte unsigned wait_period_at_the_end = LOADING_CYCLES + 2;
    integer fd_vector;
    string line;
    bit [255:0] ref_master_key;
    bit [127:0] ref_data_in;
    bit [127:0] ref_data_out;

    function new (string name = "aes256_sequence_ref_vectors");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        bit [255:0] prev_master_key;
        bit rnd_status = 'b0;
        int unsigned key_cnt = 0;
        int unsigned pt_cnt = 0;

        while (!$feof(fd_vector)) begin
            void'($fgets(line, fd_vector));
            $sscanf(line, "%h,%h,%h", ref_master_key, ref_data_in, ref_data_out);
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            
            if (prev_master_key != ref_master_key) begin // skip key expansion if master key is the same
                `uvm_info(get_type_name(), $sformatf(" ===> New Master Key. Count: %0d <===", key_cnt), UVM_MEDIUM)
                `ifdef VIVADO_RND_WORKAROUND
                item.sweep_type = SWEEP_TYPE_NONE;
                `endif
                item.key_expand_start = 1;
                item.next_val_req = 0;
                item.key_expand_start_delay = 1;
                item.key_expand_start_pulse = 1;
                item.master_key = ref_master_key;
                `SEND_ITEM(item, 0);
                prev_master_key = ref_master_key;
                key_cnt++;
            end

            `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext. Count: %0d <===", pt_cnt), UVM_MEDIUM)
            item.key_expand_start = 0;
            item.next_val_req = 1;
            item.next_val_req_delay = 1;
            item.next_val_req_pulse = 1;
            item.data_in = ref_data_in;
            `SEND_ITEM(item, 0);
            pt_cnt++;
        end
        
        item.key_expand_start = 0;
        item.next_val_req = 0;
        repeat (wait_period_at_the_end) begin
            `SEND_ITEM(item, 0);
        end

    endtask: body

endclass: aes256_sequence_ref_vectors
