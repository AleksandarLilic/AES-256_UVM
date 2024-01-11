`timescale 1ns/1ns

module aes256_loading_wrap(
    aes256_if aes256_if_conn
);

aes256_loading aes256_loading_i(
    .clk(aes256_if_conn.clk),
    .rst(aes256_if_conn.rst),
    .pi_key_expand_start(aes256_if_conn.key_expand_start),
    .pi_master_key(aes256_if_conn.master_key),
    .po_key_ready(aes256_if_conn.key_ready),
    .pi_next_val_req(aes256_if_conn.next_val_req),
    .pi_data(aes256_if_conn.data_in),
    .po_enc_done(aes256_if_conn.enc_done),
    .po_next_val_ready(aes256_if_conn.next_val_ready),
    .po_data(aes256_if_conn.data_out)
);

`ifdef HIER_ACCESS
    // hierarchical access the round keys from VHDL to avoid exposing it through the VHDL component interface
    `define AES_TOP aes256_loading_i.AES256_1
    `define KEY_EXP_TOP aes256_loading_i.AES256_1.KEY_EXPANSION_TOP_1
    `define ENC_TOP aes256_loading_i.AES256_1.ENCRYPTION_TOP_1
    `define LOADING_TOP aes256_loading_i.DATA_LOADING_1

    // used for model comparison
    assign aes256_if_conn.key_exp_round_keys = `AES_TOP.w_KEY_EXP_ROUND_KEYS_ARRAY;

    // The rest of this define is used for covergroups and toggle coverage 
    // Vivado can't do code coverage for VHDL, but toggle can be done in this way

    // key expansion module
    // TODO: add key_exp enable logic based on the TB signals and use that to sample key_exp in addition to !key_ready
    logic [255:0] key_exp_master_key;
    logic [2:0] key_exp_pr_state;
    logic [5:0] key_exp_cnt;
    assign key_exp_master_key = `KEY_EXP_TOP.pi_master_key;
    assign key_exp_pr_state = `KEY_EXP_TOP.FSM_KEY_EXPANSION_1.pr_state_logic;
    assign key_exp_cnt = `KEY_EXP_TOP.CNT_8_60_1.reg_COUNTER;
    //wire [31:0] key_exp_parser_word_in = `KEY_EXP_TOP.KEY_PARSER_1.pi_new_key_word;

    // encryption module
    logic [127:0] enc_data_in;
    logic [127:0] enc_data_out;
    logic [2:0] enc_pr_state;
    logic [3:0] enc_cnt;
    logic [127:0] enc_sub_bytes_in;
    logic [127:0] enc_sub_bytes_out;
    logic [7:0] enc_sbox_in;
    logic [7:0] enc_sbox_out;
    logic [127:0] enc_shift_rows_in;
    logic [127:0] enc_shift_rows_out;
    logic [127:0] enc_mix_columns_in;
    logic [127:0] enc_mix_columns_out;
    logic [7:0] enc_lut_lmul2_in;
    logic [7:0] enc_lut_lmul2_out;
    logic [7:0] enc_lut_lmul3_in;
    logic [7:0] enc_lut_lmul3_out;
    logic [127:0] enc_add_round_key_in; 
    logic [127:0] enc_add_round_key_round_key_in; 
    logic [127:0] enc_add_round_key_out; 

    assign enc_data_in = `ENC_TOP.pi_data;
    assign enc_data_out = `ENC_TOP.po_data;
    assign enc_pr_state = `ENC_TOP.FSM_ENCRYPTION_1.pr_state_logic;
    assign enc_cnt = `ENC_TOP.CNT_16_1.po_data;
    assign enc_sub_bytes_in = `ENC_TOP.SUB_BYTES_1.pi_data;
    assign enc_sub_bytes_out = `ENC_TOP.SUB_BYTES_1.po_data;
    assign enc_sbox_in = `ENC_TOP.SUB_BYTES_1.generate_luts[0].SBOX_i.pi_address;
    assign enc_sbox_out = `ENC_TOP.SUB_BYTES_1.generate_luts[0].SBOX_i.po_data;
    assign enc_shift_rows_in = `ENC_TOP.SHIFT_ROWS_1.pi_data;
    assign enc_shift_rows_out = `ENC_TOP.SHIFT_ROWS_1.po_data;
    assign enc_mix_columns_in = `ENC_TOP.MIX_COLUMNS_1.pi_data;
    assign enc_mix_columns_out = `ENC_TOP.MIX_COLUMNS_1.po_data;
    assign enc_lut_lmul2_in = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul2[0].MUL2_i.pi_address;
    assign enc_lut_lmul2_out = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul2[0].MUL2_i.po_data;
    assign enc_lut_lmul3_in = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul3[0].MUL3_i.pi_address;
    assign enc_lut_lmul3_out = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul3[0].MUL3_i.po_data;
    assign enc_add_round_key_in = `ENC_TOP.ADD_ROUND_KEY_1.pi_data;
    assign enc_add_round_key_round_key_in = `ENC_TOP.ADD_ROUND_KEY_1.pi_round_key;
    assign enc_add_round_key_out = `ENC_TOP.ADD_ROUND_KEY_1.po_data;

    // loading module
    logic loading_pr_state;
    assign loading_pr_state = `LOADING_TOP.pr_state_logic;

`endif // HIER_ACCESS

endmodule: aes256_loading_wrap

interface aes256_if;
    logic clk;
    logic rst;
    logic key_expand_start;
    logic [255:0] master_key;
    logic key_ready;
    logic next_val_req;
    logic [127:0] data_in;
    logic enc_done;
    logic next_val_ready;
    logic [7:0] data_out;
    `ifdef HIER_ACCESS
    logic [0:14] [127:0] key_exp_round_keys;
    `endif
endinterface: aes256_if
