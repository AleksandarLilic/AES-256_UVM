import uvm_pkg::*;
`include "aes256_cfg.svh"
`include "aes256_env.svh"

class aes256_test extends uvm_test;
    `uvm_component_utils(aes256_test)
    aes256_cfg cfg;
    aes256_env env;

    function new (string name = "aes256_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = aes256_cfg::type_id::create("cfg", this);
        uvm_config_db#(aes256_cfg)::set(this, "env", "aes256_cfg", cfg);
        env = aes256_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");
        
        // test that key generation can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 5;
            number_of_plaintexts == 0;
            wait_for_key_ready == FALSE;
            wait_period_at_the_end == 0;
        });
        seq.start(env.agent_1.sequencer_1);

        // test that encryption can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 5;
            wait_for_key_ready == TRUE;
            wait_for_enc_done == FALSE;
            wait_period_at_the_end == 0;
        });
        seq.start(env.agent_1.sequencer_1);
        
        // test simple scenario with key expansion and encryption
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 5;
            wait_for_key_ready == TRUE;
            wait_for_enc_done == TRUE;
            wait_period_at_the_end == 20;
        });
        seq.start(env.agent_1.sequencer_1);
        
        phase.drop_objection(this);
    endtask: run_phase
    
endclass: aes256_test
