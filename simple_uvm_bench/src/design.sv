// Simple adder/subtractor module

`define DESIGN_LANG_VHDL
//`define DESIGN_LANG_VERILOG

// workaround to ensure VHDL and Verilog designs are not set at the same time
`ifdef DESIGN_LANG_VHDL
    `ifdef DESIGN_LANG_VERILOG
        `error_both_DESIGN_LANG_VHDL_and_DESIGN_LANG_VERILOG_are_defined
    `endif
`else
    `ifndef DESIGN_LANG_VERILOG
        `error_neither_DESIGN_LANG_VHDL_nor_DESIGN_LANG_VERILOG_is_defined
    `endif
`endif

module ADD_SUB(
    input            clk,
    input [7:0]      a0,
    input [7:0]      b0,
    // if this is 1, add; else subtract
    input            doAdd0,
    output reg [8:0] result0
);

`ifdef DESIGN_LANG_VERILOG
    always @ (posedge clk) begin
        if (doAdd0)
            result0 <= a0 + b0;
        else
            result0 <= a0 - b0;
    end
`endif

`ifdef DESIGN_LANG_VHDL
    ADD_SUB_L vhdl_add_sub_inst(
        .clk(clk),
        .a0(a0),
        .b0(b0),
        .doAdd0(doAdd0),
        .result0(result0)
    );
`endif

endmodule


interface add_sub_if(
    input bit clk,
    input [7:0] a,
    input [7:0] b,
    input       doAdd,
    input [8:0] result
);

clocking cb @(posedge clk);
    output    a;
    output    b;
    output    doAdd;
    input     result;
endclocking

endinterface: add_sub_if


bind ADD_SUB add_sub_if add_sub_if0(
    .clk(clk),
    .a(a0),
    .b(b0),
    .doAdd(doAdd0),
    .result(result0)
);
