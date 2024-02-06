import uvm_pkg::*;
`include "aes256_inc.svh"
`include "aes256_subscriber.svh"

class aes256_sequence_ref_vectors extends uvm_sequence#(aes256_seq_item);
    `uvm_object_utils(aes256_sequence_ref_vectors)
    aes256_subscriber sub;
    byte unsigned wait_period_at_the_end = LOADING_CYCLES + 2;
    integer fd_vector;
    string line;
    bit [`MATRIX_KEY_WIDTH-1:0] ref_master_key;
    bit [`MATRIX_DATA_WIDTH-1:0] ref_data_in;
    bit [`MATRIX_DATA_WIDTH-1:0] ref_data_out;

    function new (string name = "aes256_sequence_ref_vectors");
        super.new(name);
    endfunction

    virtual task body();
        aes256_seq_item item;
        bit [`MATRIX_KEY_WIDTH-1:0] prev_master_key;
        bool_t first_key_expanded = FALSE;
        bit rnd_status = 'b0;
        int unsigned key_cnt = 0;
        int unsigned pt_cnt = 0;
        int unsigned mct_pt_cnt = 0;

        while (!$feof(fd_vector)) begin
            void'($fgets(line, fd_vector));
            $sscanf(line, "%h,%h,%h", ref_master_key, ref_data_in, ref_data_out);
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            
            if (prev_master_key != ref_master_key || first_key_expanded == FALSE) begin // skip key expansion if master key is the same
                `uvm_info(get_type_name(), $sformatf(" ===> New Master Key. Count: %0d <===", key_cnt), UVM_LOW)
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
                first_key_expanded = TRUE;
            end

            `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext. Count: %0d <===", pt_cnt), UVM_LOW)
            item.key_expand_start = 0;
            item.next_val_req = 1;
            item.next_val_req_delay = 1;
            item.next_val_req_pulse = 1;
            item.data_in = ref_data_in;
            `SEND_ITEM(item, 0);
            pt_cnt++;
            if ($test$plusargs("MCT_VECTORS")) begin
                `uvm_info(get_type_name(), $sformatf(" ===> Plaintext MCT vector iteration %0d <===", pt_cnt), UVM_LOW)
                repeat(999) begin // MCT runs 1000 times for each plaintext in the vector file
                    `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext MCT vectors. Count: %0d <===", mct_pt_cnt), UVM_MEDIUM)
                    // get CT from subscriber
                    sub.item_received.wait_trigger();
                    item.data_in = sub.item.data_out;
                    //item.next_val_req_delay = LOADING_CYCLES + 1;
                    // send it back to DUT as PT
                    `SEND_ITEM(item, 0);
                    mct_pt_cnt++;
                end
            end
        end
        
        item.key_expand_start = 0;
        item.next_val_req = 0;
        repeat (wait_period_at_the_end) begin
            `SEND_ITEM(item, 0);
        end

    endtask: body

endclass: aes256_sequence_ref_vectors
