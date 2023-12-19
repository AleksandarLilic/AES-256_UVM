import uvm_pkg::*;
`include "aes256_agent.svh"

class aes256_test extends uvm_test;
    `uvm_component_utils(aes256_test)
    aes256_agent agent_1;

    function new (string name = "aes256_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_1 = aes256_agent::type_id::create("agent_1", this);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "agent_1", "is_active", UVM_ACTIVE);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        `uvm_info(get_type_name(), "run_phase started", UVM_LOW)
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "objection raised", UVM_LOW)
        #10;
        seq = aes256_sequence::type_id::create("seq");
        `uvm_info(get_type_name(), "sequence being sent to sequencer", UVM_LOW)
        seq.start(agent_1.sequencer_1);
        `uvm_info(get_type_name(), "sequencer finished", UVM_LOW)
        phase.drop_objection(this);
        `uvm_info(get_type_name(), "objection dropped", UVM_LOW)
    endtask: run_phase
endclass: aes256_test
