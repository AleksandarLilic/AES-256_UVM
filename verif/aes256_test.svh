import uvm_pkg::*;
`include "aes256_cfg.svh"
`include "aes256_env.svh"

class aes256_test_base extends uvm_test;
    `uvm_component_utils(aes256_test_base)
    aes256_cfg cfg;
    aes256_env env;

    function new (string name = "aes256_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = aes256_cfg::type_id::create("cfg", this);
        uvm_config_db#(aes256_cfg)::set(this, "env", "aes256_cfg", cfg);
        env = aes256_env::type_id::create("env", this);
    endfunction
endclass: aes256_test_base

class aes256_test_smoke extends aes256_test_base;
    `uvm_component_utils(aes256_test_smoke)

    function new (string name = "aes256_test_smoke", uvm_component parent = null);
        super.new(name, parent);
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

        // test scenario with key expansion and encryption max throughput
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 1;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_WAIT_FOR_LOADING_END;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_smoke

class aes256_test_max_throughput extends aes256_test_base;
    `uvm_component_utils(aes256_test_max_throughput)

    function new (string name = "aes256_test_max_throughput", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        // test scenario with key expansion and encryption max throughput
        assert(seq.randomize() with {
            number_of_keys == 20;
            number_of_plaintexts == 100;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_max_throughput

class aes256_test_loading_overlaps extends aes256_test_base;
    `uvm_component_utils(aes256_test_loading_overlaps)

    function new (string name = "aes256_test_loading_overlaps", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        // test scenario with key expansion and encryption and overlap
        assert(seq.randomize() with {
            number_of_keys == 5;
            number_of_plaintexts == 100;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_OVERLAP_W_LOADING;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        // test scenario with key expansion and encryption and no overlap
        assert(seq.randomize() with {
            number_of_keys == 5;
            number_of_plaintexts == 100;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_WAIT_FOR_LOADING_END;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);
    
    phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_loading_overlaps


class aes256_test_interrupts extends aes256_test_base;
    `uvm_component_utils(aes256_test_interrupts)
    
    function new (string name = "aes256_test_interrupts", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        // test that key generation can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 100;
            number_of_plaintexts == 0;
            wait_for_key_ready == FALSE;
            exp_delay_mode == EXP_WITH_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        // test that encryption can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 10;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == FALSE;
            enc_delay_mode == ENC_WITH_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        // test scenario where loading is interrupted by new key expansion
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 100;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);
        
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 100;
            wait_for_key_ready == TRUE;
            exp_delay_mode == EXP_NO_DELAY;
            wait_for_enc_done == TRUE;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);
    
    phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_interrupts
