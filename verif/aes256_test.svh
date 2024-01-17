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
            exp_delay_mode == EXP_NO_DELAY;
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
            number_of_keys == 50;
            number_of_plaintexts == 100;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_max_throughput

class aes256_test_key_gen extends aes256_test_base;
    `uvm_component_utils(aes256_test_key_gen)

    function new (string name = "aes256_test_key_gen", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence seq;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        assert(seq.randomize() with {
            number_of_keys == 4000;
            number_of_plaintexts == 1;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_key_gen

class aes256_test_delays extends aes256_test_base;
    `uvm_component_utils(aes256_test_delays)

    function new (string name = "aes256_test_delays", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        exp_delay_mode_t exp_mode;
        enc_delay_mode_t enc_mode;
        aes256_sequence seq;
        byte unsigned plaintext_num = 0;
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        for (int i = 0; i < exp_mode.num(); i++) begin
            $cast(exp_mode, (i));
            `uvm_info(get_type_name(), $sformatf("New Expansion Delay Mode. Count: %0d, mode: %0s", i, exp_mode.name()), UVM_HIGH)
            for (int j = 0; j < enc_mode.num(); j++) begin
                $cast(enc_mode, (j));
                plaintext_num = 100;
                if (enc_mode == ENC_NO_DELAY) plaintext_num = 1; // always the same delay, no need to repeat
                `uvm_info(get_type_name(), $sformatf("New Encryption Delay Mode. Count: %0d, mode: %0s", j, enc_mode.name()), UVM_HIGH)
                assert(seq.randomize() with {
                    number_of_keys == 2;
                    number_of_plaintexts == plaintext_num;
                    exp_delay_mode == exp_mode;
                    enc_delay_mode == enc_mode;
                    wait_period_at_the_end == 20;
                })
                else `uvm_fatal(get_type_name(), "Randomization failed");
                seq.start(env.agent_1.sequencer_1);
            end // enc_mode
        end // exp_mode
    
    phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_delays

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
            exp_delay_mode == EXP_WITH_DELAY;
            // don't care about encryption, never reached
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_key_ready(FALSE);
        seq.start(env.agent_1.sequencer_1);

        // check one value at the end
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 1;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_key_ready(TRUE);
        seq.start(env.agent_1.sequencer_1);

        // test that encryption can be interrupted by new key request
        // and continue after new request
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 10;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_WITH_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_enc_done(FALSE);
        seq.start(env.agent_1.sequencer_1);

        // check one value at the end
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 1;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_enc_done(TRUE);
        seq.start(env.agent_1.sequencer_1);

        // test scenario where loading is interrupted by new key expansion
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 100;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_key_exp_wait_for_loading(FALSE);
        seq.start(env.agent_1.sequencer_1);
        
        // check one value at the end
        assert(seq.randomize() with {
            number_of_keys == 1;
            number_of_plaintexts == 1;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_key_exp_wait_for_loading(TRUE);
        seq.start(env.agent_1.sequencer_1);
    
    phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_interrupts
