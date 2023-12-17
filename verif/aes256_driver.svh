import uvm_pkg::*;

// create enum for key state with 2 state: NOT_READY and EXPANDED
typedef enum {NOT_READY, EXPANDED} key_state_t;

class aes256_driver extends uvm_driver #(aes256_seq_item);
    `uvm_component_utils(aes256_driver)
    virtual aes256_if DUT_vif;
    key_state_t key_state = NOT_READY;

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
        forever begin
            `uvm_info(get_type_name(), "run_phase started, wait for next item from sequencer", UVM_LOW)
            seq_item_port.get_next_item(item);
            `uvm_info(get_type_name(), "got next item from sequencer", UVM_LOW)
            if (item.key_expand_start == 1) begin
                `uvm_info(get_type_name(), "key expand == 1, start exp", UVM_LOW)
                key_state = NOT_READY;
                DUT_vif.master_key = item.master_key;
                DUT_vif.key_expand_start = item.key_expand_start;
                @(posedge DUT_vif.clk);
                #1;
                DUT_vif.key_expand_start = 0;
                @(posedge DUT_vif.key_ready);
                #1;
                key_state = EXPANDED;
            end
            else if (item.next_val_req == 1) begin
                `uvm_info(get_type_name(), "enc == 1, start encryption", UVM_LOW)
                if (key_state == NOT_READY)
                    `uvm_fatal(get_type_name(), "Key not expanded but new ciphertext was requested: Illegal request. Simulation aborted");
                DUT_vif.data_in = item.data_in;
                DUT_vif.next_val_req = item.next_val_req;
                @(posedge DUT_vif.clk);
                #1;
                DUT_vif.next_val_req = 0;
                @(posedge DUT_vif.next_val_ready);
                @(negedge DUT_vif.next_val_ready);
                #1;
            end
            seq_item_port.item_done();
        end
    endtask: run_phase
endclass: aes256_driver
