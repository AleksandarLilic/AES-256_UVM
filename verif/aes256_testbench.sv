`timescale 1ns/1ns

`include "uvm_macros.svh"
`include "aes256_test.svh"

module top;
import uvm_pkg::*;

aes256_if DUT_aes256_if_i();

aes256_loading_wrap DUT_aes256_loading_wrap_i(
    .aes256_if_conn(DUT_aes256_if_i)
);

initial begin
    `uvm_info("clock", "clock gen block start", UVM_LOW)
    $timeformat(-9, 0, " ns", 20);
    DUT_aes256_if_i.clk = 0;
    forever begin
        #5 DUT_aes256_if_i.clk = ~DUT_aes256_if_i.clk;
        if (DUT_aes256_if_i.clk == 1'b1) `uvm_info("clock", "clk rising edge", UVM_FULL)
    end
end

initial begin
    uvm_config_db#(virtual aes256_if)::set(null, "*", "DUT_vif", DUT_aes256_if_i);
    run_test("aes256_test");
end

endmodule
