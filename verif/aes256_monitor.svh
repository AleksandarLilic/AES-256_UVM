import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_monitor extends uvm_monitor;
    `uvm_component_utils(aes256_monitor)

    uvm_analysis_port#(aes256_seq_item) item_ap;
    virtual aes256_if DUT_vif;
    aes256_seq_item item;
    aes256_seq_item item_loading;
    bit exp_started = 0;
    bit enc_started = 0;
    byte unsigned data_out_cnt = 0;
    int unsigned ciphertext_cnt = 0;
    bit loading_interrupted = 1'b0;

    function new(string name = "aes256_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_ap = new("item_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aes256_if)::get(this, "", "DUT_vif", DUT_vif))
            `uvm_fatal(get_type_name(), "Virtual interface not defined. Simulation aborted");
    endfunction

    function void collect_inputs_exp(aes256_seq_item item);
        // when expansion starts, all previous inputs and outputs are rendered invalid
        item.key_expand_start = DUT_vif.key_expand_start;
        item.master_key = DUT_vif.master_key;
        `uvm_info(get_type_name(), $sformatf("key_expand_start: %0h, master_key: %0h", DUT_vif.master_key, DUT_vif.key_expand_start), UVM_FULL)
        collect_inputs_enc(item);
        item.data_out = 'h0;
        item.next_val_ready = 1'b0;
    endfunction

    function void collect_inputs_enc(aes256_seq_item item);
        item.next_val_req = DUT_vif.next_val_req;
        item.data_in = DUT_vif.data_in;
        `uvm_info(get_type_name(), $sformatf("next_val_req: %0h, data_in: %0h", DUT_vif.next_val_req, DUT_vif.data_in), UVM_FULL)
    endfunction

    function void collect_outputs(aes256_seq_item item, bit [3:0] cnt);
        item.data_out[cnt] = DUT_vif.data_out;
        item.next_val_ready = DUT_vif.next_val_ready;
        `uvm_info(get_type_name(), $sformatf("next_val_ready: %0h, data_out: %0h", DUT_vif.next_val_ready, DUT_vif.data_out), UVM_FULL)
    endfunction

    task run_phase(uvm_phase phase);
        item = aes256_seq_item::type_id::create("item");
        
        fork: exp_enc_loading
        forever begin: key_expansion
            // fork, as current key expansion can be interrupted by new key expansion request
            fork: expansion_progress
            begin // this side of the fork is not relevant the first time it runs (i.e. when key was not yet requested)
                @(posedge DUT_vif.key_ready);
                `uvm_info({get_type_name(), ":key_expansion"}, "Key expansion finished", UVM_HIGH)
            end
            begin
                @(posedge DUT_vif.key_expand_start);
                exp_started = 0;
                ciphertext_cnt = 0;
            end
            join_any: expansion_progress
            disable expansion_progress;
            
            while (exp_started == 0) begin
                @(posedge DUT_vif.clk or negedge DUT_vif.key_expand_start);
                collect_inputs_exp(item);
                if (DUT_vif.key_expand_start == 0) exp_started = 1;
            end
        end: key_expansion

        forever begin: timeout_check_exp
            @(posedge exp_started);
            fork: fork_key_expansion
            begin // timeout
                repeat (KEY_EXP_TIMEOUT_CLOCKS) @(posedge DUT_vif.clk);
                `uvm_fatal(get_type_name(), "Key expansion timeout. Simulation aborted");
            end
            begin // key expansion finished
                @(posedge DUT_vif.key_ready);
            end
            begin // new key expansion requested, so previous one is aborted
                @(posedge DUT_vif.key_expand_start);
            end
            join_any: fork_key_expansion
            disable fork_key_expansion;
        end: timeout_check_exp

        forever begin: encryption
            fork: enc_progress
            begin // this side of the fork is not relevant the first time it runs (i.e. when encryption was not yet requested)
                @(posedge DUT_vif.enc_done);
                `uvm_info({get_type_name(), ":encryption"}, "Encryption finished", UVM_HIGH)
            end
            begin
                @(posedge DUT_vif.next_val_req);
                enc_started = 0;
            end
            join_any: enc_progress
            disable enc_progress;
            
            while (enc_started == 0) begin
                @(posedge DUT_vif.clk or negedge DUT_vif.next_val_req);
                collect_inputs_enc(item);
                if (DUT_vif.next_val_req == 0) enc_started = 1;
            end
        end: encryption

        forever begin: timing_check_enc
            @(posedge enc_started);
            fork: fork_encryption
            begin // timeout
                repeat (ENC_TIMEOUT_CLOCKS) @(posedge DUT_vif.clk);
                `uvm_fatal(get_type_name(), "Encryption timeout. Simulation aborted");
            end
            begin // encryption finished
                @(posedge DUT_vif.enc_done);
            end
            begin // new encryption requested, so previous one is aborted
                @(posedge DUT_vif.next_val_req);
            end
            begin // key expansion requested, so previous encryption is aborted
                @(posedge DUT_vif.key_expand_start);
            end
            join_any: fork_encryption
            disable fork_encryption;
        end: timing_check_enc

        forever begin: protocol_checks
            if (DUT_vif.next_val_req == 1 && DUT_vif.key_expand_start == 1) 
                `uvm_fatal({get_type_name(), ":protocol_checks"}, "New ciphertext and new expansion requested at the same time. Invalid request. Simulation aborted");
            if (DUT_vif.next_val_req == 1 && DUT_vif.key_ready == 0) 
                `uvm_fatal({get_type_name(), ":key_expansion"}, "New ciphertext requested but the key has not been expanded yet. Invalid request. Simulation aborted");
            @(posedge DUT_vif.clk); #1;
        end: protocol_checks

        forever begin: loading
            loading_interrupted = 1'b0;
            @(posedge DUT_vif.enc_done);
            `uvm_info({get_type_name(), ":loading"}, "Encryption finished. Expecting new data packets in the next clock cycle", UVM_HIGH)
            item_loading = aes256_seq_item::type_id::create("item_loading");
            item_loading.copy(item);

            fork: wait_for_new_data
            begin
                repeat (3) @(posedge DUT_vif.clk);
                `uvm_fatal(get_type_name(), "No new data packets received. Simulation aborted");
            end
            begin
                @(posedge DUT_vif.next_val_ready);
            end
            begin: key_expansion_interrupt
                @(posedge DUT_vif.key_expand_start);
                `uvm_info({get_type_name(), ":loading"}, "Key expansion requested. Aborting wait to start loading", UVM_MEDIUM);
                loading_interrupted = 1'b1;
            end: key_expansion_interrupt
            join_any: wait_for_new_data
            disable wait_for_new_data;

            if (loading_interrupted == 1'b0) begin // only care about loading if not interrupted
                fork: load_or_exp
                begin: loading
                    data_out_cnt = 0;
                    while (DUT_vif.next_val_ready == 1) begin
                        `uvm_info({get_type_name(), ":loading"}, $sformatf("loading data: %0h, at %0d", DUT_vif.data_out, data_out_cnt), UVM_HIGH)
                        if (data_out_cnt > LOADING_CYCLES - 1) 
                            `uvm_fatal({get_type_name(), ":loading"}, "Too many data packets received. Simulation aborted");
                        collect_outputs(item_loading, LOADING_CYCLES - 1 - data_out_cnt); // MSB arrives first
                        data_out_cnt++;
                        @(posedge DUT_vif.clk);
                        #1;
                    end

                    if (data_out_cnt < LOADING_CYCLES - 1 && loading_interrupted == 'b0)
                        `uvm_fatal({get_type_name(), ":loading"}, $sformatf("Too few data packets received but loading was not interrupted. Expected: %0d, received: %0d. Simulation aborted", LOADING_CYCLES - 1, data_out_cnt));
                    
                    // print packet and send it to the analysis port
                    `uvm_info({get_type_name(), ":loading"}, $sformatf("Received ciphertext %0d\n%s", ciphertext_cnt, item_loading.sprint()), UVM_MEDIUM);
                    ciphertext_cnt++;
                    item_ap.write(item_loading);
                end: loading

                begin: key_expansion_interrupt
                    @(posedge DUT_vif.key_expand_start);
                    `uvm_info({get_type_name(), ":loading"}, "Key expansion requested. Aborting loading", UVM_MEDIUM);
                end: key_expansion_interrupt
            
            join_any: load_or_exp
            disable load_or_exp;
            end
        end: loading
        join_none: exp_enc_loading
    endtask

endclass
