`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2024 01:17:47 PM
// Design Name: 
// Module Name: esb_module_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module esb_module_tb;



reg clk = 1'b0;
reg res = 1'b1;
reg clr = 1'b1;
reg [31:0] frequency_word = 54600000;
reg [15:0] amp = 16'hF000;
reg [19:0] phase_PDH = 19'h1FFFF;

reg [21:0] phase = 22'h100000;
reg [7:0] multiplier = 42;

reg [7:0] offset_i = 0;
reg [7:0] offset_q = 0;

wire [15:0] i;
wire [15:0] q;
wire [7:0] pdh_output;



initial
begin

#5 frequency_word = 54600000;
#5 res = 1'b0;
#200 clr = 1'b0;
#10000 frequency_word = 5460000;

#20000 phase_PDH = 19'h08FFF;

#20000 clr = 1'b1;
#1000 clr = 1'b0;

end


always
begin
    #10 clk=~clk;
        //amp = amp+1;
        
end




phase_generator dut(
	.f(frequency_word), //32 bit
	.phase(phase),   //23 bit
	.multiplier(multiplier),
	.i_amp(amp),
	.q_amp(amp),
	.phase_PDH(phase_PDH),
	.clr(clr),
	.i(i),
	.q(q),
	.pdh_output(pdh_output),
	.sys_clk(clk),
	.sys_rst(res));


endmodule
