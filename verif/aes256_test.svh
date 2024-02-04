import uvm_pkg::*;
`include "aes256_cfg.svh"
`include "aes256_env.svh"
`include "aes256_subscriber.svh"

class aes256_test_base extends uvm_test;
    `uvm_component_utils(aes256_test_base)
    aes256_cfg cfg;
    aes256_env env;
    int unsigned num_keys = 0;
    int unsigned num_pts = 0;

    function new (string name = "aes256_test_base", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function set_items(int unsigned keys, int unsigned pts);
        num_keys = keys;
        num_pts = pts;
    endfunction

    function int num_items();
        return num_keys * num_pts;
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
        set_items(1, 1);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_WAIT_FOR_LOADING_END;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        env.scbd.num_expected_items += num_items();
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
        set_items(50, 100);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        env.scbd.num_expected_items += num_items();
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

        set_items(4000, 1);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        env.scbd.num_expected_items += num_items();
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
        phase.raise_objection(this);
        #10;
        seq = aes256_sequence::type_id::create("seq");

        for (int i = 0; i < exp_mode.num(); i++) begin
            $cast(exp_mode, (i));
            `uvm_info(get_type_name(), $sformatf("New Expansion Delay Mode. Count: %0d, mode: %0s", i, exp_mode.name()), UVM_HIGH)
            for (int j = 0; j < enc_mode.num(); j++) begin
                $cast(enc_mode, (j));
                set_items(2, 100);
                if (enc_mode == ENC_NO_DELAY) num_pts = 1; // always the same delay, no need to repeat
                `uvm_info(get_type_name(), $sformatf("New Encryption Delay Mode. Count: %0d, mode: %0s", j, enc_mode.name()), UVM_HIGH)
                assert(seq.randomize() with {
                    number_of_keys == num_keys;
                    number_of_plaintexts == num_pts;
                    exp_delay_mode == exp_mode;
                    enc_delay_mode == enc_mode;
                    wait_period_at_the_end == 20;
                })
                else `uvm_fatal(get_type_name(), "Randomization failed");
                env.scbd.num_expected_items += num_items();
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
        set_items(100, 0);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_WITH_DELAY;
            // don't care about encryption, never reached
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_key_ready(FALSE);
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);

        // check one value at the end
        set_items(1, 1);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_key_ready(TRUE);
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);

        // test that encryption can be interrupted by new key request
        // and continue after new request
        set_items(1, 10);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_WITH_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_enc_done(FALSE);
        // encryption is interrupted, so no items are expected
        seq.start(env.agent_1.sequencer_1);

        // check one value at the end
        set_items(1, 1);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_wait_enc_done(TRUE);
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);

        // test scenario where loading is interrupted by new key expansion
        set_items(1, 100);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 0;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_key_exp_wait_for_loading(FALSE);
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);
        
        // check one value at the end
        set_items(1, 1);
        assert(seq.randomize() with {
            number_of_keys == num_keys;
            number_of_plaintexts == num_pts;
            exp_delay_mode == EXP_NO_DELAY;
            enc_delay_mode == ENC_NO_DELAY;
            wait_period_at_the_end == 20;
        })
        else `uvm_fatal(get_type_name(), "Randomization failed");
        seq.set_key_exp_wait_for_loading(TRUE);
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);
    
    phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_interrupts

class aes256_test_sweep_key extends aes256_test_base;
    `uvm_component_utils(aes256_test_sweep_key)

    function new (string name = "aes256_test_sweep_key", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence_sweep seq;
        phase.raise_objection(this);
        #10;
        
        seq = aes256_sequence_sweep::type_id::create("seq");
        seq.sweep_type = SWEEP_TYPE_KEY;
        env.scbd.num_expected_items += 512; // 512 keys in the key sweep, 256-bit key * 2
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_sweep_key

class aes256_test_sweep_pt extends aes256_test_base;
    `uvm_component_utils(aes256_test_sweep_pt)

    function new (string name = "aes256_test_sweep_pt", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence_sweep seq;
        phase.raise_objection(this);
        #10;
        
        seq = aes256_sequence_sweep::type_id::create("seq");
        seq.sweep_type = SWEEP_TYPE_PT;
        env.scbd.num_expected_items += 256; // 256 plaintexts in the plaintext sweep, 128-bit plaintext * 2
        seq.start(env.agent_1.sequencer_1);

        phase.drop_objection(this);
    endtask: run_phase
endclass: aes256_test_sweep_pt

class aes256_test_ref_vectors extends aes256_test_base;
    `uvm_component_utils(aes256_test_ref_vectors)
    integer fd_seq;
    integer fd_scbd;
    string line;
    string ref_vectors_path;
    aes256_subscriber sub;

    function new (string name = "aes256_test_ref_vectors", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sub = aes256_subscriber::type_id::create("sub", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        env.agent_1.monitor_1.item_ap.connect(sub.item_imp);
    endfunction

    task run_phase(uvm_phase phase);
        aes256_sequence_ref_vectors seq;
        phase.raise_objection(this);
        #10;
        
        if (! $value$plusargs("ref_vectors_path=%s", ref_vectors_path))
            `uvm_fatal(get_type_name(), "ref_vectors_path not defined");
        
        fd_seq = $fopen(ref_vectors_path, "r");
        if (fd_seq == 0)
            `uvm_fatal(get_type_name(), $sformatf("Error: Unable to open file: %s", ref_vectors_path));
        void'($fgets(line, fd_seq)); // skip header line
        
        fd_scbd = $fopen(ref_vectors_path, "r");
        if (fd_scbd == 0)
            `uvm_fatal(get_type_name(), $sformatf("Error: Unable to open file: %s", ref_vectors_path));
        void'($fgets(line, fd_scbd)); // skip header line
        
        seq = aes256_sequence_ref_vectors::type_id::create("seq");
        if ($test$plusargs("MCT_VECTORS")) begin
            if ($test$plusargs("ALLOW_VECTOR_CHECKER_NONE")) begin
                `uvm_fatal(get_type_name(), "MCT_VECTORS and ALLOW_VECTOR_CHECKER_NONE cannot be used together");
            end
            seq.sub = sub;
        end
        seq.fd_vector = fd_seq;
        env.scbd.use_ref_vectors = TRUE;
        env.scbd.fd_vector = fd_scbd;
        env.scbd.num_expected_items += num_items();
        seq.start(env.agent_1.sequencer_1);
        
        phase.drop_objection(this);
        $fclose(fd_seq);
        $fclose(fd_scbd);
    endtask: run_phase
endclass: aes256_test_ref_vectors
