
module aes256_loading_wrap(
    aes256_if aes256_if_conn
);

aes256_loading DUT_aes256_loading_i(
    .clk(aes256_if_conn.clk),
    .pi_key_expand_start(aes256_if_conn.key_expand_start),
    .pi_master_key(aes256_if_conn.master_key),
    .po_key_ready(aes256_if_conn.key_ready),
    .pi_next_val_req(aes256_if_conn.next_val_req),
    .pi_data(aes256_if_conn.data_in),
    .po_next_val_ready(aes256_if_conn.next_val_ready),
    .po_data(aes256_if_conn.data_out)
);
endmodule: aes256_loading_wrap

interface aes256_if;
    logic clk;
    logic key_expand_start;
    logic [255:0] master_key;
    logic key_ready;
    logic next_val_req;
    logic [127:0] data_in;
    logic next_val_ready;
    logic [7:0] data_out;
endinterface: aes256_if
