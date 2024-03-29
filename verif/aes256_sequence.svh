import uvm_pkg::*;
`include "aes256_inc.svh"

class aes256_sequence extends uvm_sequence#(aes256_seq_item);
    rand int unsigned number_of_keys = 1;
    rand int unsigned number_of_plaintexts = 2;
    bool_t wait_for_key_ready = TRUE;
    bool_t wait_for_enc_done = TRUE;
    bool_t key_exp_wait_for_loading_end = TRUE;
    rand byte unsigned wait_period_at_the_end = 10;
    rand exp_delay_mode_t exp_delay_mode = EXP_RANDOM;
    rand enc_delay_mode_t enc_delay_mode = ENC_RANDOM;

    `uvm_object_utils_begin(aes256_sequence)
        `uvm_field_int(number_of_keys, UVM_DEFAULT)
        `uvm_field_int(number_of_plaintexts, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint c_number_of_keys { number_of_keys >= 1; }

    function new (string name = "aes256_sequence");
        super.new(name);
    endfunction

    function set_wait_key_ready(bool_t state);
        this.wait_for_key_ready = state;
    endfunction

    function set_wait_enc_done(bool_t state);
        this.wait_for_enc_done = state;
    endfunction

    function set_key_exp_wait_for_loading(bool_t state);
        this.key_exp_wait_for_loading_end = state;
    endfunction

    virtual task body();
        aes256_seq_item item;
        bit [`MATRIX_KEY_WIDTH-1:0] current_master_key;
        int unsigned key_cnt = 0;
        int unsigned pt_cnt = 0;
        bit rnd_status = 'b0;

        for (key_cnt = 0; key_cnt < number_of_keys; key_cnt++) begin
            rnd_status = 'b0;
            `uvm_info(get_type_name(), $sformatf(" ===> New Master Key. Count: %0d <===", key_cnt), UVM_LOW)
            item = aes256_seq_item::type_id::create($sformatf("item_%0d_%0d", key_cnt, pt_cnt));
            `ifdef VIVADO_RND_WORKAROUND
            item.sweep_type = SWEEP_TYPE_NONE;
            `endif
            item.key_expand_start = 1;
            item.next_val_req = 0;
            item.wait_for_key_ready = this.wait_for_key_ready;
            item.key_exp_wait_for_loading_end = this.key_exp_wait_for_loading_end;
            case (exp_delay_mode)
                EXP_NO_DELAY: rnd_status = item.randomize() with { key_expand_start_delay == 1; key_expand_start_pulse == 1; };
                EXP_WITH_DELAY: rnd_status = item.randomize() with { key_expand_start_delay > 1; };
                EXP_WITH_DELAY_LTL: rnd_status = item.randomize() with { key_expand_start_delay inside {[1:LOADING_CYCLES]}; };
                EXP_RANDOM: rnd_status = item.randomize();
                EXP_RANDOM_LONG_PULSE: rnd_status = item.randomize() with { key_expand_start_pulse > KEY_EXP_CYCLES; };
                default: `uvm_fatal(get_type_name(), "Unknown delay mode")
            endcase
            assert(rnd_status) else `uvm_fatal(get_type_name(), "Randomization failed")
            `SEND_ITEM(item, 0);
            
            current_master_key = item.master_key;
            for (pt_cnt = 0; pt_cnt < number_of_plaintexts; pt_cnt++) begin
                rnd_status = 'b0;
                `uvm_info(get_type_name(), $sformatf(" ===> New Plaintext. Count: %0d <===", pt_cnt), UVM_LOW)
                item.key_expand_start = 0;
                item.next_val_req = 1;
                item.wait_for_enc_done = this.wait_for_enc_done;
                case (enc_delay_mode)
                    ENC_NO_DELAY: rnd_status = item.randomize() with { next_val_req_delay == 1; next_val_req_pulse == 1; master_key == current_master_key; };
                    ENC_WITH_DELAY: rnd_status = item.randomize() with { next_val_req_delay > 1; master_key == current_master_key; };
                    ENC_OVERLAP_W_LOADING: rnd_status = item.randomize() with { next_val_req_delay inside {[1:LOADING_CYCLES]}; master_key == current_master_key; };
                    ENC_WAIT_FOR_LOADING_END: rnd_status = item.randomize() with { next_val_req_delay > LOADING_CYCLES; master_key == current_master_key; };
                    ENC_RANDOM: rnd_status = item.randomize() with { master_key == current_master_key; };
                    ENC_RANDOM_LONG_PULSE: rnd_status = item.randomize() with { next_val_req_pulse > ENC_CYCLES; master_key == current_master_key; };                    
                    default: `uvm_fatal(get_type_name(), "Unknown delay mode")
                endcase
                assert(rnd_status) else `uvm_fatal(get_type_name(), "Randomization failed")
                `SEND_ITEM(item, 0);
            end
        end
        
        item.key_expand_start = 0;
        item.next_val_req = 0;
        repeat (wait_period_at_the_end) begin
            `SEND_ITEM(item, 0);
        end

    endtask: body

endclass: aes256_sequence
