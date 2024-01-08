
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
assign aes256_if_conn.key_exp_round_keys = aes256_loading_i.AES256_1.w_KEY_EXP_ROUND_KEYS_ARRAY;

//`ifdef COVERAGE
// TODO: consider moving this to the header file and including it here
// top level
logic [7:0] data_out;
assign data_out = aes256_if_conn.data_out;

// key expansion module
logic [2:0] key_exp_pr_state;
assign key_exp_pr_state = aes256_loading_i.AES256_1.KEY_EXPANSION_TOP_1.FSM_KEY_EXPANSION_1.pr_state_logic;

// encryption module
logic [2:0] enc_pr_state;
assign enc_pr_state = aes256_loading_i.AES256_1.ENCRYPTION_TOP_1.FSM_ENCRYPTION_1.pr_state_logic;

logic [7:0] sbox_in;
assign sbox_in = aes256_loading_i.AES256_1.ENCRYPTION_TOP_1.SUB_BYTES_1.generate_luts[0].SBOX_i.pi_address;

// loading module
logic loading_pr_state;
assign loading_pr_state = aes256_loading_i.DATA_LOADING_1.pr_state_logic;
//`endif
`endif

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
