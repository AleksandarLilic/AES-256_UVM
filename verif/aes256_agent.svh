import uvm_pkg::*;

`include "aes256_seq_item.svh"
`include "aes256_sequence.svh"
`include "aes256_driver.svh"
`include "aes256_monitor.svh"

class aes256_agent extends uvm_agent;
    `uvm_component_utils(aes256_agent)
    aes256_driver driver_1;
    aes256_monitor monitor_1;
    uvm_sequencer#(aes256_seq_item) sequencer_1;
    aes256_cfg cfg;

    function new (string name = "aes256_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(aes256_cfg)::get(this, "", "aes256_cfg", cfg))
            `uvm_fatal(get_full_name(),"Config not found")
        
        monitor_1 = aes256_monitor::type_id::create("monitor_1", this);
        if (cfg.mode == UVM_ACTIVE) begin
            driver_1 = aes256_driver::type_id::create("driver_1", this);
            sequencer_1 = uvm_sequencer#(aes256_seq_item)::type_id::create("sequencer_1", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.mode == UVM_ACTIVE) begin
            driver_1.seq_item_port.connect(sequencer_1.seq_item_export);
        end
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        begin
        end
        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_agent
