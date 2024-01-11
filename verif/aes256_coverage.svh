
covergroup cg_256bit_data(ref logic [255:0] data_in, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_in_low : coverpoint data_in[63:0] iff (en) { option.auto_bin_max = 256; }
    data_in_mi_lo : coverpoint data_in[127:64] iff (en) { option.auto_bin_max = 256; }
    data_in_mi_hi : coverpoint data_in[191:128] iff (en) { option.auto_bin_max = 256; }
    data_in_high : coverpoint data_in[255:192] iff (en) { option.auto_bin_max = 256; }
    data_in_min_max: coverpoint data_in iff (en) { bins min = {'h0}; bins max = {CP_256_MAX}; }
endgroup

covergroup cg_128bit_data(ref logic [127:0] data_in, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_in_low : coverpoint data_in[31:0] iff (en) { option.auto_bin_max = 128; }
    data_in_mi_lo : coverpoint data_in[63:32] iff (en) { option.auto_bin_max = 128; }
    data_in_mi_hi : coverpoint data_in[95:64] iff (en) { option.auto_bin_max = 128; }
    data_in_high : coverpoint data_in[127:96] iff (en) { option.auto_bin_max = 128; }
    data_in_min_max: coverpoint data_in iff (en) { bins min = {'h0}; bins max = {CP_128_MAX}; }
endgroup

covergroup cg_8bit_LUT(ref logic [7:0] data_in, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    LUT_cp : coverpoint data_in iff (en) { option.auto_bin_max = 256; }
endgroup

covergroup cg_8bit_data(ref logic [7:0] data_in, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_cp : coverpoint data_in iff (en) { option.auto_bin_max = 256; }
endgroup

covergroup cg_key_exp (ref logic [2:0] pr_state, ref logic [5:0] cnt, ref logic state_en_n, ref logic cnt_en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;

    key_exp_state : coverpoint pr_state
    iff (!state_en_n){
        // states
        bins idle = {EXP_FSM_IDLE};
        bins key_parser = {EXP_KEY_PARSER};
        bins rot_word = {EXP_ROT_WORD};
        bins sub_word = {EXP_SUB_WORD};
        bins rcon = {EXP_RCON};
        bins xor_we = {EXP_XOR_WE};
        // transitions
            // TBD
        // illegal states
        illegal_bins others_illegal = default;
        // illegal transitions
            // TBD
    }

    counter : coverpoint cnt
    iff (cnt_en){
        bins min = {8};
        bins range = {[9:59]};
        bins max = {60};
        illegal_bins low_illegal = {[0:7]};
        illegal_bins high_illegal = {[61:63]};
    }
endgroup

covergroup cg_enc (ref logic [2:0] pr_state, ref logic [3:0] cnt, ref logic state_en, ref logic cnt_en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;

    state : coverpoint pr_state
        iff (state_en){
            // states
            bins idle = {ENC_FSM_IDLE};
            bins sub_bytes = {ENC_FSM_SUB_BYTES};
            bins shift_rows = {ENC_FSM_SHIFT_ROWS};
            bins mix_columns = {ENC_FSM_MIX_COLUMNS};
            bins add_round_key = {ENC_FSM_ADD_ROUND_KEY};
            // transitions
            bins trans_idle_ark = (ENC_FSM_IDLE => ENC_FSM_ADD_ROUND_KEY);
            bins trans_sb_sr = (ENC_FSM_SUB_BYTES => ENC_FSM_SHIFT_ROWS);
            bins trans_sr_mc = (ENC_FSM_SHIFT_ROWS => ENC_FSM_MIX_COLUMNS);
            bins trans_sr_ark = (ENC_FSM_SHIFT_ROWS => ENC_FSM_ADD_ROUND_KEY);
            bins trans_mc_ark = (ENC_FSM_MIX_COLUMNS => ENC_FSM_ADD_ROUND_KEY);
            bins trans_ark_sb = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_SUB_BYTES);
            bins trans_sb_idle = (ENC_FSM_SUB_BYTES => ENC_FSM_IDLE);
            bins trans_sr_idle = (ENC_FSM_SHIFT_ROWS => ENC_FSM_IDLE);
            bins trans_mc_idle = (ENC_FSM_MIX_COLUMNS => ENC_FSM_IDLE);
            bins trans_ark_idle = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_IDLE);
            bins trans_idle_idle = (ENC_FSM_IDLE => ENC_FSM_IDLE);
            // ilegal states
            illegal_bins others_illegal = default;
            // illegal transitions
            illegal_bins trans_from_sb = (ENC_FSM_SUB_BYTES => ENC_FSM_SUB_BYTES, ENC_FSM_MIX_COLUMNS, ENC_FSM_ADD_ROUND_KEY);
            illegal_bins trans_from_sr = (ENC_FSM_SHIFT_ROWS => ENC_FSM_SHIFT_ROWS, ENC_FSM_SUB_BYTES);
            illegal_bins trans_from_mc = (ENC_FSM_MIX_COLUMNS => ENC_FSM_MIX_COLUMNS, ENC_FSM_SUB_BYTES, ENC_FSM_SHIFT_ROWS);
            illegal_bins trans_from_ark = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_ADD_ROUND_KEY, ENC_FSM_SHIFT_ROWS, ENC_FSM_MIX_COLUMNS);
        }
    
    counter : coverpoint cnt
        iff (cnt_en){
            // TBD: probably can solve this with bins range, no need for each counter bin
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
endgroup

logic key_exp_cnt_en;
logic enc_cnt_en;
logic sub_bytes_en;
logic shift_rows_en;
logic mix_columns_en;
logic add_round_key_en;
assign key_exp_cnt_en = (`DUT.key_exp_pr_state != 0);
assign enc_cnt_en = (`DUT.enc_pr_state != ENC_FSM_IDLE);
assign sub_bytes_en = (`DUT.enc_pr_state == ENC_FSM_SUB_BYTES);
assign shift_rows_en = (`DUT.enc_pr_state == ENC_FSM_SHIFT_ROWS);
assign mix_columns_en = (`DUT.enc_pr_state == ENC_FSM_MIX_COLUMNS);
assign add_round_key_en = (`DUT.enc_pr_state == ENC_FSM_ADD_ROUND_KEY);

initial begin
    if ($test$plusargs("COVERAGE")) begin
        // key
        cg_key_exp cg_key_exp_i = new(`DUT.key_exp_pr_state, `DUT.key_exp_cnt, DUT_aes256_if_i.key_ready, key_exp_cnt_en);
        cg_256bit_data master_key = new(`DUT.key_exp_master_key, DUT_aes256_if_i.key_expand_start);
        // enc
        cg_enc cg_enc_i = new(`DUT.enc_pr_state, `DUT.enc_cnt, DUT_aes256_if_i.key_ready, enc_cnt_en);
        cg_128bit_data enc_data_in = new(`DUT.enc_data_in, DUT_aes256_if_i.next_val_req);
        cg_128bit_data enc_data_out = new(`DUT.enc_data_out, DUT_aes256_if_i.enc_done);
        cg_128bit_data sub_bytes_in = new(`DUT.enc_sub_bytes_in, sub_bytes_en);
        cg_128bit_data sub_bytes_out = new(`DUT.enc_sub_bytes_out, sub_bytes_en);
        cg_8bit_LUT sbox_in = new(`DUT.enc_sbox_in, sub_bytes_en);
        cg_8bit_LUT sbox_out = new(`DUT.enc_sbox_out, sub_bytes_en);
        cg_128bit_data shift_rows_in = new(`DUT.enc_shift_rows_in, shift_rows_en);
        cg_128bit_data shift_rows_out = new(`DUT.enc_shift_rows_out, shift_rows_en);
        cg_128bit_data mix_columns_in = new(`DUT.enc_mix_columns_in, mix_columns_en);
        cg_128bit_data mix_columns_out = new(`DUT.enc_mix_columns_out, mix_columns_en);
        cg_8bit_LUT lmul2_in = new(`DUT.enc_lut_lmul2_in, mix_columns_en);
        cg_8bit_LUT lmul2_out = new(`DUT.enc_lut_lmul2_out, mix_columns_en);
        cg_8bit_LUT lmul3_in = new(`DUT.enc_lut_lmul3_in, mix_columns_en);
        cg_8bit_LUT lmul3_out = new(`DUT.enc_lut_lmul3_out, mix_columns_en);
        cg_128bit_data add_round_key_in = new(`DUT.enc_add_round_key_in, add_round_key_en);
        cg_128bit_data add_round_key_round_key_in = new(`DUT.enc_add_round_key_round_key_in, add_round_key_en);
        cg_128bit_data add_round_key_out = new(`DUT.enc_add_round_key_out, add_round_key_en);
        // loading
        cg_8bit_data loading_data_out = new(DUT_aes256_if_i.data_out, DUT_aes256_if_i.next_val_ready);
    end
end
