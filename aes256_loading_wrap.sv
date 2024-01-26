`timescale 1ns/1ns

`include "aes256_inc.svh"

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

    // used for C model comparison in scoreboard
    assign aes256_if_conn.key_exp_round_keys = `AES_TOP.w_KEY_EXP_ROUND_KEYS_ARRAY;

    // The rest of this define is used for covergroups and toggle coverage 
    // Vivado can't do code coverage for VHDL, but toggle can be done in this way

    // key expansion module
    // TODO: add key_exp enable logic based on the TB signals and use that to sample key_exp in addition to !key_ready
    logic [`MATRIX_KEY_WIDTH-1:0] master_key;
    logic [2:0] key_exp_pr_state;
    logic [5:0] key_exp_cnt;
    logic key_exp_cnt_en;
    logic [`WORD_WIDTH-1:0] key_parser_cr_word_out;
    logic [`WORD_WIDTH-1:0] key_parser_pr_word_out;
    logic key_parser_en;
    logic [`WORD_WIDTH-1:0] rot_word_in;
    logic [`WORD_WIDTH-1:0] rot_word_out;
    logic rot_word_en;
    logic [`WORD_WIDTH-1:0] sub_word_in;
    logic [`WORD_WIDTH-1:0] sub_word_out;
    logic sub_word_en;
    logic [`WORD_WIDTH-1:0] rcon_out;
    logic [7:0] lut_rcon_in;
    logic [`WORD_WIDTH-1:0] lut_rcon_out;
    logic rcon_en;
    logic [`WORD_WIDTH-1:0] xor_sync_in_1;
    logic [`WORD_WIDTH-1:0] xor_sync_out;
    logic xor_sync_en;
    assign master_key = `KEY_EXP_TOP.pi_master_key;
    assign key_exp_pr_state = `KEY_EXP_TOP.FSM_KEY_EXPANSION_1.pr_state_logic;
    assign key_exp_cnt = `KEY_EXP_TOP.CNT_8_60_1.po_data;
    assign key_exp_cnt_en = `KEY_EXP_TOP.CNT_8_60_1.pi_enable;
    assign key_parser_cr_word_out = `KEY_EXP_TOP.KEY_PARSER_1.po_current_key_word;
    assign key_parser_pr_word_out = `KEY_EXP_TOP.KEY_PARSER_1.po_previous_key_word;
    assign key_parser_en = `KEY_EXP_TOP.KEY_PARSER_1.pi_enable;
    assign rot_word_in = `KEY_EXP_TOP.ROT_WORD_1.pi_data;
    assign rot_word_out = `KEY_EXP_TOP.ROT_WORD_1.po_rot_word_data;
    assign rot_word_en = `KEY_EXP_TOP.ROT_WORD_1.pi_enable;
    assign sub_word_in = `KEY_EXP_TOP.SUB_WORD_1.pi_data;
    assign sub_word_out = `KEY_EXP_TOP.SUB_WORD_1.po_sub_word_data;
    assign sub_word_en = `KEY_EXP_TOP.SUB_WORD_1.pi_enable;
    assign rcon_out = `KEY_EXP_TOP.RCON_1.po_rcon_data;
    assign lut_rcon_in = `KEY_EXP_TOP.RCON_1.RCON0.pi_address;
    assign lut_rcon_out = `KEY_EXP_TOP.RCON_1.RCON0.po_data;
    assign rcon_en = `KEY_EXP_TOP.RCON_1.pi_enable;
    assign xor_sync_in_1 = `KEY_EXP_TOP.XOR_1.pi_data_1;
    assign xor_sync_out = `KEY_EXP_TOP.XOR_1.po_xor_data;
    assign xor_sync_en = `KEY_EXP_TOP.XOR_1.pi_enable;

    // encryption module
    logic [`MATRIX_DATA_WIDTH-1:0] enc_data_in;
    logic [`MATRIX_DATA_WIDTH-1:0] enc_data_out;
    logic [2:0] enc_pr_state;
    logic [3:0] enc_cnt;
    logic enc_cnt_en;
    logic [`MATRIX_DATA_WIDTH-1:0] sub_bytes_out;
    logic [7:0] sbox_in;
    logic [7:0] sbox_out;
    logic sub_bytes_en;
    logic [`MATRIX_DATA_WIDTH-1:0] shift_rows_out;
    logic shift_rows_en;
    logic [`MATRIX_DATA_WIDTH-1:0] mix_columns_out;
    logic [7:0] lut_lmul2_in;
    logic [7:0] lut_lmul2_out;
    logic [7:0] lut_lmul3_in;
    logic [7:0] lut_lmul3_out;
    logic mix_columns_en;
    logic [`MATRIX_DATA_WIDTH-1:0] add_round_key_in; 
    logic [`MATRIX_ROUND_KEY_WIDTH-1:0] add_round_key_round_key_in; 
    logic [`MATRIX_DATA_WIDTH-1:0] add_round_key_out; 
    logic add_round_key_en;

    assign enc_data_in = `ENC_TOP.pi_data;
    assign enc_data_out = `ENC_TOP.po_data;
    assign enc_pr_state = `ENC_TOP.FSM_ENCRYPTION_1.pr_state_logic;
    assign enc_cnt = `ENC_TOP.CNT_16_1.po_data;
    assign enc_cnt_en = `ENC_TOP.CNT_16_1.pi_enable;
    assign sub_bytes_out = `ENC_TOP.SUB_BYTES_1.po_data;
    assign sbox_in = `ENC_TOP.SUB_BYTES_1.generate_luts[0].SBOX_i.pi_address;
    assign sbox_out = `ENC_TOP.SUB_BYTES_1.generate_luts[0].SBOX_i.po_data;
    assign sub_bytes_en = `ENC_TOP.reg_FSM_SUB_BYTES_EN;
    assign shift_rows_out = `ENC_TOP.SHIFT_ROWS_1.po_data;
    assign shift_rows_en = `ENC_TOP.reg_FSM_SHIFT_ROWS_EN;
    assign mix_columns_out = `ENC_TOP.MIX_COLUMNS_1.po_data;
    assign lut_lmul2_in = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul2[0].MUL2_i.pi_address;
    assign lut_lmul2_out = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul2[0].MUL2_i.po_data;
    assign lut_lmul3_in = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul3[0].MUL3_i.pi_address;
    assign lut_lmul3_out = `ENC_TOP.MIX_COLUMNS_1.generate_luts_mul3[0].MUL3_i.po_data;
    assign mix_columns_en = `ENC_TOP.reg_FSM_MIX_COLUMNS_EN;
    assign add_round_key_in = `ENC_TOP.ADD_ROUND_KEY_1.pi_data;
    assign add_round_key_round_key_in = `ENC_TOP.ADD_ROUND_KEY_1.pi_round_key;
    assign add_round_key_out = `ENC_TOP.ADD_ROUND_KEY_1.po_data;
    assign add_round_key_en = `ENC_TOP.reg_FSM_ADD_ROUND_KEY_EN;

    // loading module
    logic loading_pr_state;
    logic [3:0] loading_cnt;
    logic [7:0] loading_data_out;
    assign loading_pr_state = `LOADING_TOP.pr_state_logic;
    assign loading_cnt = `LOADING_TOP.reg_COUNTER;
    assign loading_data_out = `LOADING_TOP.po_data;

`endif // HIER_ACCESS

endmodule: aes256_loading_wrap

`include "uvm_macros.svh"
interface aes256_if;
    import uvm_pkg::*;

    // signals
    logic clk;
    logic rst;
    logic key_expand_start;
    logic [`MATRIX_KEY_WIDTH-1:0] master_key;
    logic key_ready;
    logic next_val_req;
    logic [`MATRIX_DATA_WIDTH-1:0] data_in;
    logic enc_done;
    logic next_val_ready;
    logic [7:0] data_out;
    `ifdef HIER_ACCESS
    logic [0:`N_ROUNDS-1] [`MATRIX_ROUND_KEY_WIDTH-1:0] key_exp_round_keys;
    `endif

    // DUT Asertions
    // ensure 'key_ready' does not go high one or more cycles after 'key_expand_start' is high
    // one cycle is to account for DUT's response on the new key_expansion request after previous key_expansion was completed
    property p_not_key_ready_during_key_expand_start;
        @(posedge clk) disable iff (rst) 
            key_expand_start |-> ##[1:$] !key_ready;
    endproperty
    assert_not_key_ready_during_key_expand_start: assert property (p_not_key_ready_during_key_expand_start)
        else `uvm_fatal("aes256_if", "DUT Invalid behavior: key_ready went high while key_expand_start is high.");

    // when 'key_expand_start' goes high while 'key_ready' is high, 'key_ready' should go low in the next cycle
    property p_not_key_ready_after_new_key_expand_start;
        @(posedge clk) disable iff (rst)
            (key_ready && key_expand_start) |-> ##1 !key_ready;
    endproperty
    assert_not_key_ready_after_new_key_expand_start: assert property (p_not_key_ready_after_new_key_expand_start)
        else `uvm_fatal("aes256_if", "DUT Invalid behavior: key_ready did not go low after key_expand_start went high.");

    // ensure 'enc_done' does not go high one or more cycles after 'next_val_req' is high
    property p_not_enc_done_during_next_val_req;
        @(posedge clk) disable iff (rst)
            next_val_req |-> ##[1:$] !enc_done;
    endproperty
    assert_not_enc_done_during_next_val_req: assert property (p_not_enc_done_during_next_val_req)
        else `uvm_fatal("aes256_if", "DUT Invalid behavior: enc_done went high while next_val_req is high.");
    
    // TB Assertions
    // ensure 'next_val_req' does not go high while 'key_expand_start' is high
    property p_not_next_val_req_during_key_expand_start;
        @(posedge clk) disable iff (rst)
            key_expand_start |-> !next_val_req throughout key_expand_start;
    endproperty
    assert_not_next_val_req_during_key_expand_start: assert property (p_not_next_val_req_during_key_expand_start)
        else `uvm_fatal("aes256_if", "TB Invalid behavior: next_val_req went high while key_expand_start is high.");

    // ensure 'next_val_req' does not go high while 'key_ready' is low
    property p_not_next_val_req_when_not_key_not_ready;
        @(posedge clk) disable iff (rst)
            !key_ready |-> !next_val_req throughout !key_ready;
    endproperty
    assert_not_next_val_req_when_not_key_not_ready: assert property (p_not_next_val_req_when_not_key_not_ready)
        else `uvm_fatal("aes256_if", "TB Invalid behavior: next_val_req went high while key_ready is low.");

endinterface: aes256_if
