`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:33:08 12/10/2014 
// Design Name: 
// Module Name:    addsub 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module addsub (
	input [7:0] a,
	input [7:0] b,
	output [7:0] y,
	input add_sub,
	input decen,
	input carry_in,
	output reg carry_out
);
	reg [7:0] b_i;
	reg c_i;
	
	reg corr_lsb;
	reg corr_msb;
	
	reg halfcarry;
	reg [4:0] halfcarry_tmp;
	reg [7:0] corr;
	
	reg [8:0] result_bin;
	reg [8:0] result;

	always @(*) begin
		if (add_sub)
			if (decen)
				b_i = 8'h99 - b;
			else
				b_i = ~b;
		else
			b_i = b;
	end

	always @(*) begin
		c_i = carry_in ^ add_sub;
		result_bin = a + b_i + c_i;
		
		halfcarry_tmp = a[3:0] + b_i[3:0] + c_i;
		halfcarry = halfcarry_tmp[4];
	
		corr_lsb = halfcarry | (result_bin[3] & (result_bin[2] | result_bin[1]));
		corr_msb = result_bin[8] | (result_bin[7] & ((result_bin[6] | result_bin[5]) | (result_bin[4] & (halfcarry ^ corr_lsb))));
	
		if (corr_lsb && corr_msb)
			corr = 8'h66;
		else if (corr_lsb)
			corr = 8'h06;
		else if (corr_msb)
			corr = 8'h60;
		else
			corr = 0;
		
		if (decen) begin
			result = result_bin[7:0] + corr;
			carry_out = result[8] | result_bin[8];
		end else begin
			result = result_bin;
			carry_out = result_bin[8];
		end
	end

	assign y = result[7:0];

endmodule
