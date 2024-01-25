
covergroup cg_256bit_data(ref logic [`MATRIX_KEY_WIDTH-1:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_low_cp : coverpoint data[63:0] iff (en) { option.auto_bin_max = 256; }
    data_mi_lo_cp : coverpoint data[127:64] iff (en) { option.auto_bin_max = 256; }
    data_mi_hi_cp : coverpoint data[191:128] iff (en) { option.auto_bin_max = 256; }
    data_high_cp : coverpoint data[255:192] iff (en) { option.auto_bin_max = 256; }
    data_min_max_cp: coverpoint data iff (en) { bins min = {'h0}; bins max = {CP_256_MAX}; }
endgroup

covergroup cg_128bit_data(ref logic [`MATRIX_DATA_WIDTH-1:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_low_cp : coverpoint data[31:0] iff (en) { option.auto_bin_max = 128; }
    data_mi_lo_cp : coverpoint data[63:32] iff (en) { option.auto_bin_max = 128; }
    data_mi_hi_cp : coverpoint data[95:64] iff (en) { option.auto_bin_max = 128; }
    data_high_cp : coverpoint data[127:96] iff (en) { option.auto_bin_max = 128; }
    data_min_max_cp: coverpoint data iff (en) { bins min = {'h0}; bins max = {CP_128_MAX}; }
endgroup

covergroup cg_32bit_data(ref logic [31:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_low_cp : coverpoint data[7:0] iff (en) { option.auto_bin_max = 32; }
    data_mi_lo_cp : coverpoint data[15:8] iff (en) { option.auto_bin_max = 32; }
    data_mi_hi_cp : coverpoint data[23:16] iff (en) { option.auto_bin_max = 32; }
    data_high_cp : coverpoint data[31:24] iff (en) { option.auto_bin_max = 32; }
    data_min_max_cp: coverpoint data iff (en) { bins min = {'h0}; bins max = {CP_32_MAX}; }
endgroup

covergroup cg_8bit_LUT(ref logic [7:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    LUT_cp : coverpoint data iff (en) { option.auto_bin_max = 256; }
endgroup

covergroup cg_8bit_data(ref logic [7:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    data_cp : coverpoint data iff (en) { option.auto_bin_max = 256; }
endgroup

covergroup cg_rcon_LUT_in(ref logic [7:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    LUT_cp : coverpoint data iff (en) {
        bins rcon_1 = {8'h08};
        bins rcon_2 = {8'h10};
        bins rcon_3 = {8'h18};
        bins rcon_4 = {8'h20};
        bins rcon_5 = {8'h28};
        bins rcon_6 = {8'h30};
        bins rcon_7 = {8'h38};
        illegal_bins others_illegal = default;
    } 
endgroup

covergroup cg_rcon_LUT_out(ref logic [31:0] data, ref logic en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;
    LUT_cp : coverpoint data iff (en) {
        bins rcon_1 = {32'h0100_0000};
        bins rcon_2 = {32'h0200_0000};
        bins rcon_3 = {32'h0400_0000};
        bins rcon_4 = {32'h0800_0000};
        bins rcon_5 = {32'h1000_0000};
        bins rcon_6 = {32'h2000_0000};
        bins rcon_7 = {32'h4000_0000};
        illegal_bins others_illegal = default;
    } 
endgroup

covergroup cg_key_exp (ref logic [2:0] pr_state, ref logic [5:0] cnt, ref logic state_en_n, ref logic cnt_en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;

    key_exp_state_cp : coverpoint pr_state
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

    counter_cp : coverpoint cnt
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

    state_cp : coverpoint pr_state
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
    
    counter_cp : coverpoint cnt
        iff (cnt_en){
            bins min = {0};
            bins range = {[1:12]};
            bins max = {13};
            illegal_bins cnt_14_15 = {14,15};
        }
endgroup

covergroup cg_loading (ref logic [3:0] cnt, ref logic cnt_en) @(posedge DUT_aes256_if_i.clk);
    type_option.goal = 100;
    type_option.weight = 1;
    option.per_instance = 1;

    counter_cp : coverpoint cnt
        iff (cnt_en){
            bins min = {0};
            bins range = {[1:14]};
            bins max = {15};
        }
endgroup

initial begin
    if ($test$plusargs("FUNC_COVERAGE")) begin
        // key exp
        static cg_key_exp cg_key_exp_i = new(`DUT.key_exp_pr_state, `DUT.key_exp_cnt, DUT_aes256_if_i.key_ready, `DUT.key_exp_cnt_en);
        static cg_256bit_data master_key = new(`DUT.master_key, DUT_aes256_if_i.key_expand_start);
        static cg_32bit_data key_parser_cr_word_out = new(`DUT.key_parser_cr_word_out, `DUT.key_parser_en);
        static cg_32bit_data key_parser_pr_word_out = new(`DUT.key_parser_pr_word_out, `DUT.key_parser_en);
        static cg_32bit_data rot_word_in = new(`DUT.rot_word_in, `DUT.rot_word_en);
        static cg_32bit_data rot_word_out = new(`DUT.rot_word_out, `DUT.rot_word_en);
        static cg_32bit_data sub_word_in = new(`DUT.sub_word_in, `DUT.sub_word_en);
        static cg_32bit_data sub_word_out = new(`DUT.sub_word_out, `DUT.sub_word_en);
        static cg_32bit_data rcon_out = new(`DUT.rcon_out, `DUT.rcon_en);
        static cg_rcon_LUT_in lut_rcon_in = new(`DUT.lut_rcon_in, `DUT.rcon_en);
        static cg_rcon_LUT_out lut_rcon_out = new(`DUT.lut_rcon_out, `DUT.rcon_en);
        static cg_32bit_data xor_sync_in_1 = new(`DUT.xor_sync_in_1, `DUT.xor_sync_en);
        static cg_32bit_data xor_sync_out = new(`DUT.xor_sync_out, `DUT.xor_sync_en);
        // enc
        static cg_enc cg_enc_i = new(`DUT.enc_pr_state, `DUT.enc_cnt, DUT_aes256_if_i.key_ready, `DUT.enc_cnt_en);
        static cg_128bit_data enc_data_in = new(`DUT.enc_data_in, DUT_aes256_if_i.next_val_req);
        static cg_128bit_data enc_data_out = new(`DUT.enc_data_out, DUT_aes256_if_i.enc_done);
        static cg_128bit_data sub_bytes_out = new(`DUT.sub_bytes_out, `DUT.sub_bytes_en);
        static cg_8bit_LUT sbox_in = new(`DUT.sbox_in, `DUT.sub_bytes_en);
        static cg_8bit_LUT sbox_out = new(`DUT.sbox_out, `DUT.sub_bytes_en);
        static cg_128bit_data shift_rows_out = new(`DUT.shift_rows_out, `DUT.shift_rows_en);
        static cg_128bit_data mix_columns_out = new(`DUT.mix_columns_out, `DUT.mix_columns_en);
        static cg_8bit_LUT lmul2_in = new(`DUT.lut_lmul2_in, `DUT.mix_columns_en);
        static cg_8bit_LUT lmul2_out = new(`DUT.lut_lmul2_out, `DUT.mix_columns_en);
        static cg_8bit_LUT lmul3_in = new(`DUT.lut_lmul3_in, `DUT.mix_columns_en);
        static cg_8bit_LUT lmul3_out = new(`DUT.lut_lmul3_out, `DUT.mix_columns_en);
        static cg_128bit_data add_round_key_in = new(`DUT.add_round_key_in, `DUT.add_round_key_en);
        static cg_128bit_data add_round_key_round_key_in = new(`DUT.add_round_key_round_key_in, `DUT.add_round_key_en);
        static cg_128bit_data add_round_key_out = new(`DUT.add_round_key_out, `DUT.add_round_key_en);
        // loading
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
    `DUT.master_key or
    `DUT.key_exp_pr_state or
    `DUT.key_exp_cnt or
    `DUT.key_exp_cnt_en or
    `DUT.key_parser_cr_word_out or
    `DUT.key_parser_pr_word_out or
    `DUT.key_parser_en or
    `DUT.rot_word_in or
    `DUT.rot_word_out or
    `DUT.rot_word_en or
    `DUT.sub_word_in or
    `DUT.sub_word_out or
    `DUT.sub_word_en or
    `DUT.rcon_out or
    `DUT.lut_rcon_in or
    `DUT.lut_rcon_out or
    `DUT.rcon_en or
    `DUT.xor_sync_in_1 or
    `DUT.xor_sync_out or
    `DUT.xor_sync_en or
    // enc
    `DUT.enc_data_in or
    `DUT.enc_data_out or
    `DUT.enc_pr_state or
    `DUT.enc_cnt or
    `DUT.enc_cnt_en or
    `DUT.sub_bytes_out or
    `DUT.sbox_in or
    `DUT.sbox_out or
    `DUT.sub_bytes_en or
    `DUT.shift_rows_out or
    `DUT.shift_rows_en or
    `DUT.mix_columns_out or
    `DUT.lut_lmul2_in or
    `DUT.lut_lmul2_out or
    `DUT.lut_lmul3_in or
    `DUT.lut_lmul3_out or
    `DUT.mix_columns_en or
    `DUT.add_round_key_in or
    `DUT.add_round_key_round_key_in or
    `DUT.add_round_key_out or
    `DUT.add_round_key_en or
    // loading
    `DUT.loading_pr_state or
    `DUT.loading_cnt or
    `DUT.loading_data_out)
    begin 
        tc_dummy <= 1'b1;
    end
