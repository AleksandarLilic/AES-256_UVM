import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_driver extends uvm_driver #(aes256_seq_item);
    `uvm_component_utils(aes256_driver)
    virtual aes256_if DUT_vif;

    function new (string name = "aes256_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aes256_if)::get(this, "", "DUT_vif", DUT_vif))
            `uvm_fatal(get_type_name(), "Virtual interface not defined. Simulation aborted");
    endfunction

    task run_phase(uvm_phase phase);
        aes256_seq_item item;
        DUT_vif.master_key = 'h0;
        DUT_vif.key_expand_start = 'h0;
        DUT_vif.data_in = 'h0;
        DUT_vif.next_val_req = 'h0;
        DUT_vif.rst = 1'b1;
        @(posedge DUT_vif.clk);
        #1;
        DUT_vif.rst = 1'b0;
        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info(get_type_name(), $sformatf("Got item\n%s", item.sprint()), UVM_HIGH)
            if (item.key_expand_start == 1) begin
                if (DUT_vif.next_val_ready == 1 || DUT_vif.enc_done == 1) begin
                    // if loading is in progress or about to start
                    // either wait or allow interrupt
                    if (item.key_exp_wait_for_loading_end == TRUE) @(negedge DUT_vif.next_val_ready);
                    else `uvm_info(get_type_name(), "Loading not waited for before key expansion", UVM_MEDIUM)
                end
                `uvm_info(get_type_name(), "Key expansion started", UVM_MEDIUM)
                repeat (item.key_expand_start_delay) @(posedge DUT_vif.clk);
                #1;
                // seqeunce to start key expansion: begin
                DUT_vif.master_key = item.master_key;
                DUT_vif.key_expand_start = item.key_expand_start;
                repeat (item.key_expand_start_pulse) @(posedge DUT_vif.clk);
                #1;
                DUT_vif.key_expand_start = 0;
                // seqeunce to start key expansion: end
                if (item.wait_for_key_ready == TRUE) @(posedge DUT_vif.key_ready);
                else `uvm_info(get_type_name(), "Key expansion not waited for", UVM_MEDIUM)
            end else if (item.next_val_req == 1) begin
                `uvm_info(get_type_name(), "New ciphertext requested", UVM_MEDIUM)
                repeat (item.next_val_req_delay) @(posedge DUT_vif.clk);
                #1;
                // seqeunce to start encryption: begin
                DUT_vif.data_in = item.data_in;
                DUT_vif.next_val_req = item.next_val_req;
                repeat (item.next_val_req_pulse) @(posedge DUT_vif.clk);
                #1;
                DUT_vif.next_val_req = 0;
                // seqeunce to start encryption: end
                if (item.wait_for_enc_done == TRUE) @(posedge DUT_vif.enc_done);
                else `uvm_info(get_type_name(), "Encryption not waited for", UVM_MEDIUM)
            end else begin
                `uvm_info(get_type_name(), $sformatf("Inactive sequence item"), UVM_HIGH)
                DUT_vif.next_val_req = item.next_val_req;
                DUT_vif.key_expand_start = item.key_expand_start;
                DUT_vif.data_in = item.data_in;
                DUT_vif.master_key = item.master_key;
                @(posedge DUT_vif.clk);
                #1;
            end
            seq_item_port.item_done();
        end
    endtask: run_phase
endclass: aes256_driver
