
module top_module();

import "DPI-C" pure function int count_s();
import "DPI-C" pure function int count();

int i;
int i_s;
wire [31:0] inc_out;
inc_module inc_module_i(
    .in1(i),
    .in2(i_s),
    .out(inc_out)
);

initial begin
    #1;
    repeat(5)
    begin
        #1;
        i = count();
        i_s = count_s();
        $display("after call i = %0d", i);
        $display("after call i_s = %0d", i_s);
    end
    #1;

    $display("inc_out: %0d:", inc_out);
    $display("final i = %0d", i);
    $display("final i_s = %0d", i_s);
    if( inc_out == 6)
        $display("pass");
    else
        $display("fail");
    $finish();

end

endmodule
