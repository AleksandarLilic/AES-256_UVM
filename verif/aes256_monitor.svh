import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_monitor extends uvm_monitor;
    `uvm_component_utils(aes256_monitor)
    virtual aes256_if DUT_vif;
    aes256_seq_item item;
    bit exp_started = 0;
    bit enc_started = 0;
    byte unsigned data_out_cnt = 0;

    function new (string name = "aes256_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aes256_if)::get(this, "", "DUT_vif", DUT_vif))
            `uvm_fatal(get_type_name(), "Virtual interface not defined. Simulation aborted");
    endfunction

    function void collect_inputs_exp();
        // when expansion starts, all previous inputs and outputs are rendered invalid
        item.key_expand_start = DUT_vif.key_expand_start;
        item.master_key = DUT_vif.master_key;
        `uvm_info(get_type_name(), $sformatf("key_expand_start: %0h, master_key: %0h", DUT_vif.master_key, DUT_vif.key_expand_start), UVM_FULL)
        collect_inputs_enc();
        item.data_out = 'h0;
        item.next_val_ready = 1'b0;
    endfunction

    function void collect_inputs_enc();
        item.next_val_req = DUT_vif.next_val_req;
        item.data_in = DUT_vif.data_in;
        `uvm_info(get_type_name(), $sformatf("next_val_req: %0h, data_in: %0h", DUT_vif.next_val_req, DUT_vif.data_in), UVM_FULL)
    endfunction

    function void collect_outputs(bit [3:0] cnt);
        item.data_out[cnt] = DUT_vif.data_out;
        item.next_val_ready = DUT_vif.next_val_ready;
        `uvm_info(get_type_name(), $sformatf("next_val_ready: %0h, data_out: %0h", DUT_vif.next_val_ready, DUT_vif.data_out), UVM_FULL)
    endfunction

    task run_phase(uvm_phase phase);
        item = aes256_seq_item::type_id::create("item");
        fork: exp_enc_loading
            forever begin: key_expansion
                exp_started = 0;
                @(posedge DUT_vif.key_expand_start);
                collect_inputs_exp();
                while (exp_started == 0) begin
                    @(posedge DUT_vif.clk or negedge DUT_vif.key_expand_start);
                    if (DUT_vif.key_expand_start == 0) begin
                        exp_started = 1;
                    end
                end
                @(posedge DUT_vif.key_ready);
                `uvm_info({get_type_name(), ":key_expansion"}, "Key expansion finished", UVM_HIGH)
                exp_started = 0;
            end: key_expansion

            forever begin: encryption
                enc_started = 0;
                @(posedge DUT_vif.next_val_req);
                collect_inputs_enc();
                while (enc_started == 0) begin
                    @(posedge DUT_vif.clk or negedge DUT_vif.next_val_req);
                    if (DUT_vif.next_val_req == 0) begin
                        enc_started = 1;
                    end
                end
                @(posedge DUT_vif.enc_done);
                `uvm_info({get_type_name(), ":encryption"}, "Encryption finished", UVM_HIGH)
                enc_started = 0;
            end: encryption

            forever begin: loading
                @(posedge DUT_vif.enc_done);
                `uvm_info({get_type_name(), ":loading"}, "Encryption finished. Expecting new data packets in the next clock cycle", UVM_HIGH)
                // TODO: add cycle count, throw warning if exceeded
                // still throw error if 2x exceeded
                fork: wait_for_new_data
                    begin
                        repeat (3) @(posedge DUT_vif.clk);
                        `uvm_fatal(get_type_name(), "No new data packets received. Simulation aborted");
                    end
                    begin
                        @(posedge DUT_vif.next_val_ready);
                    end
                join_any: wait_for_new_data
                disable wait_for_new_data;

                data_out_cnt = 0;
                while (DUT_vif.next_val_ready == 1) begin
                    `uvm_info({get_type_name(), ":loading"}, $sformatf("loading data: %0h, at %0d", DUT_vif.data_out, data_out_cnt), UVM_HIGH)
                    if (data_out_cnt > 15) `uvm_fatal({get_type_name(), ":loading"}, "Too many data packets received. Simulation aborted");
                    collect_outputs(15-data_out_cnt); // MSB arrives first
                    data_out_cnt++;
                    @(posedge DUT_vif.clk);
                    #1;
                end
                `uvm_info({get_type_name(), ":loading"}, $sformatf("Received new data packets\n%s", item.sprint()), UVM_MEDIUM);
            end: loading
        join_none: exp_enc_loading
    endtask

endclass