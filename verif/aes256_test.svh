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
        
        // test that key generation can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 10;
            number_of_plaintexts == 0;
            wait_for_key_ready == FALSE;
            wait_period_at_the_end == 0;
        });
        seq.start(agent_1.sequencer_1);
        
        // test simple scenario with one key and 10 plaintexts
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 10;
            wait_for_key_ready == TRUE;
            wait_period_at_the_end == 20;
        });
        seq.start(agent_1.sequencer_1);
        
        phase.drop_objection(this);
    endtask: run_phase
    
endclass: aes256_test
