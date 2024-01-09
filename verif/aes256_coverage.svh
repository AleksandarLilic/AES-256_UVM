
covergroup cg_top();
    option.name = "top_level";
    option.per_instance = 1;
    option.goal = 100;

    data_out : coverpoint DUT_aes256_loading_wrap_i.data_out 
    iff (DUT_aes256_if_i.next_val_ready == 1'b1){
        option.auto_bin_max = 256;
    }

endgroup

covergroup cg_key_exp();
    option.name = "key_expansion_module";
    option.per_instance = 1;
    option.goal = 100;

    master_key_in_low : coverpoint DUT_aes256_loading_wrap_i.key_exp_master_key[63:0]
        iff (DUT_aes256_if_i.key_expand_start){ option.auto_bin_max = 128; }
    master_key_in_mi_lo : coverpoint DUT_aes256_loading_wrap_i.key_exp_master_key[127:64]
        iff (DUT_aes256_if_i.key_expand_start){ option.auto_bin_max = 128; }
    master_key_in_mi_hi : coverpoint DUT_aes256_loading_wrap_i.key_exp_master_key[191:128]
        iff (DUT_aes256_if_i.key_expand_start){ option.auto_bin_max = 128; }
    master_key_in_high : coverpoint DUT_aes256_loading_wrap_i.key_exp_master_key[255:192]
        iff (DUT_aes256_if_i.key_expand_start){ option.auto_bin_max = 128; }

    // type state is (idle, key_parser, rot_word, sub_word, rcon, xor_we);
    key_exp_state : coverpoint DUT_aes256_loading_wrap_i.key_exp_pr_state
    iff (!DUT_aes256_if_i.key_ready){
        option.weight = 2;
        bins idle = {0};
        bins key_parser = {1};
        bins rot_word = {2};
        bins sub_word = {3};
        bins rcon = {4};
        bins xor_we = {5};
        illegal_bins others_illegal = default;
    }

//    counter : coverpoint DUT_aes256_loading_wrap_i.key_exp_cnt
//    iff (!DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.key_exp_pr_state != 0){
//        option.goal = 100;
//        bins min = {8};
//        bins range = {[9:59]};
//        bins max = {60};
//        illegal_bins low_illegal = {[0:7]};
//        illegal_bins high_illegal = {[61:63]};
//    }
        
endgroup

covergroup cg_enc();
    option.name = "encryption_module";
    option.per_instance = 1;
    option.goal = 99;

    data_in_low : coverpoint DUT_aes256_loading_wrap_i.enc_data_in[31:0]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.next_val_req){ option.auto_bin_max = 128; }
    data_in_mi_lo : coverpoint DUT_aes256_loading_wrap_i.enc_data_in[63:32]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.next_val_req){ option.auto_bin_max = 128; }
    data_in_mi_hi : coverpoint DUT_aes256_loading_wrap_i.enc_data_in[95:64]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.next_val_req){ option.auto_bin_max = 128; }
    data_in_high : coverpoint DUT_aes256_loading_wrap_i.enc_data_in[127:96]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.next_val_req){ option.auto_bin_max = 128; }

    data_out_low : coverpoint DUT_aes256_loading_wrap_i.enc_data_out[31:0]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.enc_done){ option.auto_bin_max = 128; }
    data_out_mi_lo : coverpoint DUT_aes256_loading_wrap_i.enc_data_out[63:32]
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.enc_done){ option.auto_bin_max = 128; }
    data_out_mi_hi : coverpoint DUT_aes256_loading_wrap_i.enc_data_out[95:64]
       iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.enc_done){ option.auto_bin_max = 128; }
    data_out_high : coverpoint DUT_aes256_loading_wrap_i.enc_data_out[127:96]
      iff (DUT_aes256_if_i.key_ready && DUT_aes256_if_i.enc_done){ option.auto_bin_max = 128; }

    // type state is (idle, sub_bytes, shift_rows, mix_columns, add_round_key);
    state : coverpoint DUT_aes256_loading_wrap_i.enc_pr_state 
        iff (DUT_aes256_if_i.key_ready){
            option.weight = 2;
            option.goal = 100;
            bins idle = {ENC_FSM_IDLE};
            bins sub_bytes = {ENC_FSM_SUB_BYTES};
            bins shift_rows = {ENC_FSM_SHIFT_ROWS};
            bins mix_columns = {ENC_FSM_MIX_COLUMNS};
            bins add_round_key = {ENC_FSM_ADD_ROUND_KEY};
            illegal_bins others_illegal = default;
        }
    
    counter : coverpoint DUT_aes256_loading_wrap_i.enc_cnt
        iff (DUT_aes256_if_i.key_ready && DUT_aes256_loading_wrap_i.enc_pr_state != ENC_FSM_IDLE){
            option.goal = 100;
            bins cnt_0 = {0};
            bins cnt_1 = {1};
            bins cnt_2 = {2};
            bins cnt_3 = {3};
            bins cnt_4 = {4};
            bins cnt_5 = {5};
            bins cnt_6 = {6};
            bins cnt_7 = {7};
            bins cnt_8 = {8};
            bins cnt_9 = {9};
            bins cnt_10 = {10};
            bins cnt_11 = {11};
            bins cnt_12 = {12};
            bins cnt_13 = {13};
            bins cnt_14 = {14};
            illegal_bins cnt_15 = {15};
        }
    
    sub_bytes_in : coverpoint DUT_aes256_loading_wrap_i.enc_sub_bytes_in iff (`SUB_BYTES_EN){ `CP_128; }
    sub_bytes_out : coverpoint DUT_aes256_loading_wrap_i.enc_sub_bytes_out iff (`SUB_BYTES_EN){ `CP_128; }
    sub_bytes_sbox_in : coverpoint DUT_aes256_loading_wrap_i.enc_sbox_in
        iff (`SUB_BYTES_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }
    sub_bytes_sbox_out : coverpoint DUT_aes256_loading_wrap_i.enc_sbox_out
        iff (`SUB_BYTES_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }

    shift_rows_in : coverpoint DUT_aes256_loading_wrap_i.enc_shift_rows_in iff (`SHIFT_ROWS_EN){ `CP_128; }
    shift_rows_out : coverpoint DUT_aes256_loading_wrap_i.enc_shift_rows_out iff (`SHIFT_ROWS_EN){ `CP_128; }

    mix_columns_in : coverpoint DUT_aes256_loading_wrap_i.enc_mix_columns_in iff (`MIX_COLUMNS_EN){ `CP_128; }
    mix_columns_out : coverpoint DUT_aes256_loading_wrap_i.enc_mix_columns_out iff (`MIX_COLUMNS_EN){ `CP_128; }
    mix_columns_lut_lmul2_in : coverpoint DUT_aes256_loading_wrap_i.enc_lut_lmul2_in
        iff (`MIX_COLUMNS_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }
    mix_columns_lut_lmul2_out : coverpoint DUT_aes256_loading_wrap_i.enc_lut_lmul2_out
        iff (`MIX_COLUMNS_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }
    mix_columns_lut_lmul3_in : coverpoint DUT_aes256_loading_wrap_i.enc_lut_lmul3_in
        iff (`MIX_COLUMNS_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }
    mix_columns_lut_lmul3_out : coverpoint DUT_aes256_loading_wrap_i.enc_lut_lmul3_out
        iff (`MIX_COLUMNS_EN){
            option.goal = 100;
            option.weight = 2;
            option.auto_bin_max = 256;
        }

    add_round_key_in : coverpoint DUT_aes256_loading_wrap_i.enc_add_round_key_in iff (`ADD_ROUND_KEY_EN){ `CP_128; }
    add_round_key_round_key_in : coverpoint DUT_aes256_loading_wrap_i.enc_add_round_key_round_key_in iff (`ADD_ROUND_KEY_EN){ `CP_128; }
    add_round_key_out : coverpoint DUT_aes256_loading_wrap_i.enc_add_round_key_out iff (`ADD_ROUND_KEY_EN){ `CP_128; }
    
endgroup

covergroup cg_loading();
    option.name = "loading_module";
    option.per_instance = 1;
    option.goal = 100;

    // type state is (idle, loading);
    loading_state : coverpoint DUT_aes256_loading_wrap_i.loading_pr_state
    iff (DUT_aes256_if_i.next_val_ready == 1'b1){
        bins idle = {0};
        bins loading = {1};
        illegal_bins others_illegal = default;
    }
endgroup

cg_top cg_top_i = new();
cg_key_exp cg_key_exp_i = new();
cg_enc cg_enc_i = new();
cg_loading cg_loading_i = new();

initial begin
    forever begin
        @(posedge DUT_aes256_if_i.clk);
        cg_top_i.sample();
        cg_enc_i.sample();
        cg_key_exp_i.sample();
        cg_loading_i.sample();
    end
end
