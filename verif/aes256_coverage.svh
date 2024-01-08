
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

    // type state is (idle, key_parser, rot_word, sub_word, rcon, xor_we);
    key_exp_state : coverpoint DUT_aes256_loading_wrap_i.key_exp_pr_state
    iff (!DUT_aes256_if_i.key_ready){
        bins idle = {0};
        bins key_parser = {1};
        bins rot_word = {2};
        bins sub_word = {3};
        bins rcon = {4};
        bins xor_we = {5};
        illegal_bins others_illegal = default;
    }
endgroup

covergroup cg_enc();
    option.name = "encryption_module";
    option.per_instance = 1;
    option.goal = 100;

    // type state is (idle, sub_bytes, shift_rows, mix_columns, add_round_key);
    enc_state : coverpoint DUT_aes256_loading_wrap_i.enc_pr_state 
    iff (DUT_aes256_if_i.key_ready){
        bins idle = {0};
        bins sub_bytes = {1};
        bins shift_rows = {2};
        bins mix_columns = {3};
        bins add_round_key = {4};
        illegal_bins others_illegal = default;
    }
    
    sub_bytes_sbox_in : coverpoint DUT_aes256_loading_wrap_i.sbox_in
    iff (DUT_aes256_if_i.key_ready){
        option.auto_bin_max = 256;
    }
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
