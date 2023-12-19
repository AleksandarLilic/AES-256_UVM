import uvm_pkg::*;

// create enum for key state with 2 state: NOT_READY and EXPANDED
typedef enum {NOT_READY, EXPANDED} key_state_t;

class aes256_driver extends uvm_driver #(aes256_seq_item);
    `uvm_component_utils(aes256_driver)
    virtual aes256_if DUT_vif;
    key_state_t key_state = NOT_READY;
    const shortint unsigned KEY_EXP_TIMEOUT_CLOCKS = 100;
    const shortint unsigned ENC_TIMEOUT_CLOCKS = 100;

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
            seq_item_port.get_next_item(item);
            if (item.key_expand_start == 1) begin
                `uvm_info(get_type_name(), $sformatf("key_expand_start: %0d", item.key_expand_start), UVM_HIGH)
                key_state = NOT_READY;
                repeat (item.key_expand_start_delay) @(posedge DUT_vif.clk);
                DUT_vif.master_key = item.master_key;
                DUT_vif.key_expand_start = item.key_expand_start;
                repeat (item.key_expand_start_pulse) @(posedge DUT_vif.clk);
                #1;
                DUT_vif.key_expand_start = 0;
                fork: fork_key_expansion
                    begin
                        repeat (KEY_EXP_TIMEOUT_CLOCKS) @(posedge DUT_vif.clk);
                        `uvm_fatal(get_type_name(), "Key expansion timeout. Simulation aborted");
                    end
                    begin
                        @(posedge DUT_vif.key_ready);
                        key_state = EXPANDED;
                    end 
                join_any: fork_key_expansion
                disable fork_key_expansion;
            end
            else if (item.next_val_req == 1) begin
                `uvm_info(get_type_name(), $sformatf("next_val_req: %0d", item.next_val_req), UVM_HIGH)
                if (key_state == NOT_READY)
                    `uvm_fatal(get_type_name(), "Key not expanded but new ciphertext was requested: Illegal request. Simulation aborted");
                repeat (item.next_val_req_delay) @(posedge DUT_vif.clk);
                DUT_vif.data_in = item.data_in;
                DUT_vif.next_val_req = item.next_val_req;
                repeat (item.next_val_req_pulse) @(posedge DUT_vif.clk);
                #1;
                DUT_vif.next_val_req = 0;
                // TODO: it's legal to get request for new key expansion while encrypting
                // encryption should be aborted in that case
                // it's also valid to get request for new ciphertext while encrypting
                // current encryption should be aborted in that case
                fork: fork_encryption
                    begin
                        repeat (ENC_TIMEOUT_CLOCKS) @(posedge DUT_vif.clk);
                        `uvm_fatal(get_type_name(), "Encryption timeout. Simulation aborted");
                    end
                    begin
                        @(posedge DUT_vif.next_val_ready);
                        // FIXME: request can come in when loading is working, but needs 
                        // mechanism to pipeline this with new request
                        // using negedge for now
                        @(negedge DUT_vif.next_val_ready);
                    end
                join_any: fork_encryption
                disable fork_encryption;
                #1;
                repeat (item.wait_at_the_end) @(posedge DUT_vif.clk);
            end
            else begin
                `uvm_info(get_type_name(), $sformatf("Inactive sequence item"), UVM_HIGH)
                DUT_vif.next_val_req = item.next_val_req;
                DUT_vif.key_expand_start = item.key_expand_start;
                DUT_vif.data_in = item.data_in;
                DUT_vif.master_key = item.master_key;
            end
            seq_item_port.item_done();
        end
    endtask: run_phase
endclass: aes256_driver
