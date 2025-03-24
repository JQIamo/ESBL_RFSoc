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
reg [31:0] frequency_word = 546000;
reg [15:0] amp_i = 16'hFFFF;
reg [15:0] amp_q = 16'hFFFF;
reg [19:0] phase_PDH = 19'h1FFFF;

reg [21:0] phase = 22'h100000;
reg [7:0] multiplier = 82;

reg [7:0] offset_i = 0;
reg [7:0] offset_q = 0;
reg [47:0] nco_freq = 5460000*65536;
reg [19:0] nco_phase = 0;

wire [15:0] i;
wire [15:0] q;
wire [7:0] pdh_output;
wire [7:0] pdh_output_par;
wire [31:0] packed_output;




initial
begin



#5 frequency_word = 1460;
#5 res = 1'b0;
#200 clr = 1'b0;
#20000 frequency_word = 2000000;

#20000 phase_PDH = 19'h08FFF;

//#20000 nco_freq = 2460000*65536;


//#200000 clr = 1'b1;
//#1000 clr = 1'b0;

end


always
begin
    #10 clk=~clk;
        //amp = amp+1;
        
end


phase_generator_parallel dut1(

	.f(frequency_word), //32 bit
	.phase(phase),   //23 bit
	.multiplier(multiplier),
	.i_amp(amp_i),
	.q_amp(amp_q),
	.phase_PDH(phase_PDH),
	.clr(clr),
	.packed_output(packed_output),
	.pdh_output(pdh_output),
	.sys_clk(clk),
	.sys_rst(res));
	
	
//phase_generator_parallel dut2(
//    .f_1(nco_freq),
//    .p(nco_phase),
//	.f(frequency_word), //32 bit
//	.phase(phase),   //23 bit
//	.multiplier(multiplier),
//	.i_amp(amp_i),
//	.q_amp(amp_q),
//	.phase_PDH(phase_PDH),
//	.clr(clr),
//	.packed_output(packed_output),
//	.pdh_output(pdh_output_par),
//	.sys_clk(clk),
//	.sys_rst(res));


endmodule
