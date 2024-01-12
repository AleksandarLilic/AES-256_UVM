
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
        bins key_parser = {EXP_FSM_KEY_PARSER};
        bins rot_word = {EXP_FSM_ROT_WORD};
        bins sub_word = {EXP_FSM_SUB_WORD};
        bins rcon = {EXP_FSM_RCON};
        bins xor_we = {EXP_FSM_XOR_WE};
        // transitions
        bins trans_idle_kp = (EXP_FSM_IDLE => EXP_FSM_KEY_PARSER);
        bins trans_kp_rw = (EXP_FSM_KEY_PARSER => EXP_FSM_ROT_WORD);
        bins trans_rw_sw = (EXP_FSM_ROT_WORD => EXP_FSM_SUB_WORD);
        bins trans_sw_rcon = (EXP_FSM_SUB_WORD => EXP_FSM_RCON);
        bins trans_sw_xor = (EXP_FSM_SUB_WORD => EXP_FSM_XOR_WE);
        bins trans_rcon_xor = (EXP_FSM_RCON => EXP_FSM_XOR_WE);
        bins trans_xor_rw = (EXP_FSM_XOR_WE => EXP_FSM_ROT_WORD);
        bins trans_xor_sw = (EXP_FSM_XOR_WE => EXP_FSM_SUB_WORD);
        bins trans_xor_xor = (EXP_FSM_XOR_WE => EXP_FSM_XOR_WE);
        bins trans_kp_idle = (EXP_FSM_KEY_PARSER => EXP_FSM_IDLE);
        bins trans_rw_idle = (EXP_FSM_ROT_WORD => EXP_FSM_IDLE);
        bins trans_sw_idle = (EXP_FSM_SUB_WORD => EXP_FSM_IDLE);
        bins trans_rcon_idle = (EXP_FSM_RCON => EXP_FSM_IDLE);
        bins trans_xor_idle = (EXP_FSM_XOR_WE => EXP_FSM_IDLE);
        bins trans_idle_idle = (EXP_FSM_IDLE => EXP_FSM_IDLE);
        // illegal states
        illegal_bins others_illegal = default;
        // illegal transitions
        illegal_bins illegal_trans_from_idle = (EXP_FSM_IDLE => EXP_FSM_ROT_WORD, EXP_FSM_SUB_WORD, EXP_FSM_RCON, EXP_FSM_XOR_WE);
        illegal_bins illegal_trans_from_kp = (EXP_FSM_KEY_PARSER => EXP_FSM_KEY_PARSER, EXP_FSM_SUB_WORD, EXP_FSM_RCON, EXP_FSM_XOR_WE);
        illegal_bins illegal_trans_from_rw = (EXP_FSM_ROT_WORD => EXP_FSM_ROT_WORD, EXP_FSM_KEY_PARSER, EXP_FSM_RCON, EXP_FSM_XOR_WE);
        illegal_bins illegal_trans_from_sw = (EXP_FSM_SUB_WORD => EXP_FSM_SUB_WORD, EXP_FSM_KEY_PARSER, EXP_FSM_ROT_WORD);
        illegal_bins illegal_trans_from_rcon = (EXP_FSM_RCON => EXP_FSM_RCON, EXP_FSM_KEY_PARSER, EXP_FSM_ROT_WORD, EXP_FSM_SUB_WORD);
        illegal_bins illegal_trans_from_xor = (EXP_FSM_XOR_WE => EXP_FSM_KEY_PARSER, EXP_FSM_RCON);
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
            bins trans_ark_sb = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_SUB_BYTES);
            bins trans_sb_sr = (ENC_FSM_SUB_BYTES => ENC_FSM_SHIFT_ROWS);
            bins trans_sr_mc = (ENC_FSM_SHIFT_ROWS => ENC_FSM_MIX_COLUMNS);
            bins trans_sr_ark = (ENC_FSM_SHIFT_ROWS => ENC_FSM_ADD_ROUND_KEY);
            bins trans_mc_ark = (ENC_FSM_MIX_COLUMNS => ENC_FSM_ADD_ROUND_KEY);
            bins trans_sb_idle = (ENC_FSM_SUB_BYTES => ENC_FSM_IDLE);
            bins trans_sr_idle = (ENC_FSM_SHIFT_ROWS => ENC_FSM_IDLE);
            bins trans_mc_idle = (ENC_FSM_MIX_COLUMNS => ENC_FSM_IDLE);
            bins trans_ark_idle = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_IDLE);
            bins trans_idle_idle = (ENC_FSM_IDLE => ENC_FSM_IDLE);
            // ilegal states
            illegal_bins others_illegal = default;
            // illegal transitions
            illegal_bins illegal_trans_from_idle = (ENC_FSM_IDLE => ENC_FSM_SUB_BYTES, ENC_FSM_SHIFT_ROWS, ENC_FSM_MIX_COLUMNS);
            illegal_bins illegal_trans_from_sb = (ENC_FSM_SUB_BYTES => ENC_FSM_SUB_BYTES, ENC_FSM_MIX_COLUMNS, ENC_FSM_ADD_ROUND_KEY);
            illegal_bins illegal_trans_from_sr = (ENC_FSM_SHIFT_ROWS => ENC_FSM_SHIFT_ROWS, ENC_FSM_SUB_BYTES);
            illegal_bins illegal_trans_from_mc = (ENC_FSM_MIX_COLUMNS => ENC_FSM_MIX_COLUMNS, ENC_FSM_SUB_BYTES, ENC_FSM_SHIFT_ROWS);
            illegal_bins illegal_trans_from_ark = (ENC_FSM_ADD_ROUND_KEY => ENC_FSM_ADD_ROUND_KEY, ENC_FSM_SHIFT_ROWS, ENC_FSM_MIX_COLUMNS);
        }
    
    counter : coverpoint cnt
        iff (cnt_en){
            bins min = {0};
            bins range = {[1:13]};
            bins max = {14};
            illegal_bins cnt_15 = {15};
        }
endgroup

covergroup cg_loading (ref logic [3:0] cnt, ref logic cnt_en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;

    counter : coverpoint cnt
        iff (cnt_en){
            bins min = {0};
            bins range = {[1:14]};
            bins max = {15};
        }

endgroup

logic key_exp_cnt_en;
logic enc_cnt_en;
logic sub_bytes_en;
logic shift_rows_en;
logic mix_columns_en;
logic add_round_key_en;
assign key_exp_cnt_en = (`DUT.key_exp_pr_state != EXP_FSM_IDLE);
assign key_parser_en = (`DUT.key_exp_pr_state == EXP_FSM_KEY_PARSER);
assign rot_word_en = (`DUT.key_exp_pr_state == EXP_FSM_ROT_WORD);
assign sub_word_en = (`DUT.key_exp_pr_state == EXP_FSM_SUB_WORD);
assign rcon_en = (`DUT.key_exp_pr_state == EXP_FSM_RCON);
assign xor_we_en = (`DUT.key_exp_pr_state == EXP_FSM_XOR_WE);
assign enc_cnt_en = (`DUT.enc_pr_state != ENC_FSM_IDLE);
assign sub_bytes_en = (`DUT.enc_pr_state == ENC_FSM_SUB_BYTES);
assign shift_rows_en = (`DUT.enc_pr_state == ENC_FSM_SHIFT_ROWS);
assign mix_columns_en = (`DUT.enc_pr_state == ENC_FSM_MIX_COLUMNS);
assign add_round_key_en = (`DUT.enc_pr_state == ENC_FSM_ADD_ROUND_KEY);

initial begin
    if ($test$plusargs("COVERAGE")) begin
        // key exp
        static cg_key_exp cg_key_exp_i = new(`DUT.key_exp_pr_state, `DUT.key_exp_cnt, DUT_aes256_if_i.key_ready, key_exp_cnt_en);
        static cg_256bit_data master_key = new(`DUT.key_exp_master_key, DUT_aes256_if_i.key_expand_start);
        // enc
        static cg_enc cg_enc_i = new(`DUT.enc_pr_state, `DUT.enc_cnt, DUT_aes256_if_i.key_ready, enc_cnt_en);
        static cg_128bit_data enc_data_in = new(`DUT.enc_data_in, DUT_aes256_if_i.next_val_req);
        static cg_128bit_data enc_data_out = new(`DUT.enc_data_out, DUT_aes256_if_i.enc_done);
        static cg_128bit_data sub_bytes_in = new(`DUT.enc_sub_bytes_in, sub_bytes_en);
        static cg_128bit_data sub_bytes_out = new(`DUT.enc_sub_bytes_out, sub_bytes_en);
        static cg_8bit_LUT sbox_in = new(`DUT.enc_sbox_in, sub_bytes_en);
        static cg_8bit_LUT sbox_out = new(`DUT.enc_sbox_out, sub_bytes_en);
        static cg_128bit_data shift_rows_in = new(`DUT.enc_shift_rows_in, shift_rows_en);
        static cg_128bit_data shift_rows_out = new(`DUT.enc_shift_rows_out, shift_rows_en);
        static cg_128bit_data mix_columns_in = new(`DUT.enc_mix_columns_in, mix_columns_en);
        static cg_128bit_data mix_columns_out = new(`DUT.enc_mix_columns_out, mix_columns_en);
        static cg_8bit_LUT lmul2_in = new(`DUT.enc_lut_lmul2_in, mix_columns_en);
        static cg_8bit_LUT lmul2_out = new(`DUT.enc_lut_lmul2_out, mix_columns_en);
        static cg_8bit_LUT lmul3_in = new(`DUT.enc_lut_lmul3_in, mix_columns_en);
        static cg_8bit_LUT lmul3_out = new(`DUT.enc_lut_lmul3_out, mix_columns_en);
        static cg_128bit_data add_round_key_in = new(`DUT.enc_add_round_key_in, add_round_key_en);
        static cg_128bit_data add_round_key_round_key_in = new(`DUT.enc_add_round_key_round_key_in, add_round_key_en);
        static cg_128bit_data add_round_key_out = new(`DUT.enc_add_round_key_out, add_round_key_en);
        // loading
        static cg_128bit_data loading_data_in = new(`DUT.loading_data_in, DUT_aes256_if_i.enc_done);
        static cg_loading cg_loading_i = new(`DUT.loading_cnt, DUT_aes256_if_i.next_val_ready);
        static cg_8bit_data loading_data_out = new(`DUT.loading_data_out, DUT_aes256_if_i.next_val_ready);
    end
end

// Vivado 2023.2 (Linux) toggle coverage workaround
// if signal is not being 'listened' to, somehow it won't be covered with toggle coverage
// adding a toggle coverage dummy bit and adding all relevant signals in the sensitivity list will make the tool collect toggle coverage
// of each signal in the sensitivity list
// dummy bit still won't be covered
bit tc_dummy = 0;
always @(
    // key exp
    `DUT.key_exp_master_key or
    `DUT.key_exp_pr_state or
    `DUT.key_exp_cnt or
    // enc
    `DUT.enc_data_in or
    `DUT.enc_data_out or
    `DUT.enc_pr_state or
    `DUT.enc_cnt or
    `DUT.enc_sub_bytes_in or
    `DUT.enc_sub_bytes_out or
    `DUT.enc_sbox_in or
    `DUT.enc_sbox_out or
    `DUT.enc_shift_rows_in or
    `DUT.enc_shift_rows_out or
    `DUT.enc_mix_columns_in or
    `DUT.enc_mix_columns_out or
    `DUT.enc_lut_lmul2_in or
    `DUT.enc_lut_lmul2_out or
    `DUT.enc_lut_lmul3_in or
    `DUT.enc_lut_lmul3_out or
    `DUT.enc_add_round_key_in or
    `DUT.enc_add_round_key_round_key_in or
    `DUT.enc_add_round_key_out or 
    // loading
    `DUT.loading_data_in or
    `DUT.loading_pr_state or
    `DUT.loading_cnt or
    `DUT.loading_data_out)
    begin 
        tc_dummy <= ~tc_dummy;
    end
