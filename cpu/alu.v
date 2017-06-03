`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:42:38 12/05/2014 
// Design Name: 
// Module Name:    alu 
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
//	0	Y = A
// 	1	Y = A + B + carry					N,V,Z,C
//	2	Y = A AND B							N,Z
//	3	Y = {A[6:0],0}, carry = A[7]		N,Z,C
//	4	Y = A AND B							N,V,Z
// 	5	Y = A - B							N,Z,C
//	6	Y = A - 1							N,Z
// 	7	Y = A + 1							N,Z
// 	8	Y = A XOR B							N,Z
//	9	Y = A								N,Z
//	A	Y = {0,A[7:1]}, carry = A[0]		N,Z,C
//	B	Y = A OR B							N,Z
//	C	Y = {A[6:0],carry}, carry = A[7]	N,Z,C
//	D	Y = {carry,A[7:1]}, carry = A[0]	N,Z,C
//	E	Y = A - B - !carry					N,V,Z,C
//	F	Y = A + B + hidden carry			HC
//////////////////////////////////////////////////////////////////////////////////
module alu #(parameter BCD_EN = 1) (
	input 		[7:0] 	a,
	input 		[7:0] 	b,
	output reg 	[7:0] 	y,
	input 		[7:0] 	flags_i,
	output 		[7:0] 	flags_o,
	output reg 			p_load,
	input 		[3:0] 	alu_op
);
	
	wire 			carry_i;
	reg 			carry_o;
	wire 			zero_i;
	reg 			zero_o;
	wire 			bcden;
	wire		 	hcarry_i;
	reg 			hcarry_o;
	wire 			overf_i;
	reg 			overf_o;
	wire 			sign_i;
	reg 			sign_o;
	
	wire 	[7:0] 	addsub_y;
	reg 			add_sub;
	reg 			addsub_carry_in;
	wire 			addsub_carry_out;
	
	wire 	[7:0] 	yand;
	wire 	[7:0] 	yeor;
	wire 	[7:0] 	yora;
	
	reg 			inc_dec;
	wire 	[7:0] 	b_i;
	reg 			decen;
	
	assign carry_i 		= flags_i[0];
	assign flags_o[0] 	= carry_o;
	assign zero_i 		= flags_i[1];
	assign flags_o[1] 	= zero_o;
	assign bcden	 	= flags_i[3];
	assign hcarry_i		= flags_i[5];
	assign flags_o[5] 	= hcarry_o;
	assign overf_i 		= flags_i[6];
	assign flags_o[6] 	= overf_o;
	assign sign_i 		= flags_i[7];
	assign flags_o[7] 	= sign_o;
	
	assign flags_o[2] 	= flags_i[2];
	assign flags_o[3] 	= flags_i[3];
	assign flags_o[4] 	= flags_i[4];
	
	assign yand 		= a & b;
	assign yeor 		= a ^ b;
	assign yora 		= a | b;
	
	assign b_i 			= inc_dec? 8'h01: b;
	
	addsub u_addsub
	(
		.a				(a),
		.b				(b_i),
		.y				(addsub_y),
		.add_sub		(add_sub),
		.decen			(decen),
		.carry_in		(addsub_carry_in),
		.carry_out		(addsub_carry_out)
	);
	
	always @(*) begin
		carry_o = carry_i;
		zero_o = zero_i;
		hcarry_o = hcarry_i;
		overf_o = overf_i;
		sign_o = sign_i;
		p_load = 1;
		
		add_sub = 0;
		addsub_carry_in = carry_i;
		
		inc_dec = 0;
		decen = 0;
		
		case (alu_op)
			4'h0: begin
				y = a;
				p_load = 0;
			end
			
			4'h1: begin
				y = addsub_y;
				overf_o = (a[7] ^ addsub_y[7]) & (b[7] ^ addsub_y[7]);
				sign_o = addsub_y[7];
				zero_o = ~(| addsub_y);
				carry_o = addsub_carry_out;
				if (BCD_EN)
					decen = bcden;
			end
			
			4'h2: begin
				y = yand;
				sign_o = yand[7];
				zero_o = ~(| yand);
			end
			
			4'h3: begin
				y = {a[6:0], 1'b0};
				sign_o = a[6];
				carry_o = a[7];
				zero_o = ~(| a[6:0]);
			end
			
			4'h4: begin
				y = yand;
				sign_o = b[7];
				overf_o = b[6];
				zero_o = ~(| yand);
			end
			
			4'h5: begin
				y = addsub_y;
				add_sub = 1;
				addsub_carry_in = 0;
				sign_o = addsub_y[7];
				zero_o = ~(| addsub_y[7:0]);
				carry_o = addsub_carry_out;
			end
			
			4'h6: begin
				y = addsub_y;
				add_sub = 1;
				inc_dec = 1;
				addsub_carry_in = 0;
				sign_o = addsub_y[7];
				zero_o = ~(| addsub_y);
			end
			
			4'h7: begin
				y = addsub_y;
				inc_dec = 1;
				addsub_carry_in = 0;
				sign_o = addsub_y[7];
				zero_o = ~(| addsub_y);
			end
			
			4'h8: begin
				y = yeor;
				sign_o = yeor[7];
				zero_o = ~(| yeor);
			end
			
			4'h9: begin
				y = a;
				sign_o = a[7];
				zero_o = ~(| a);
			end
			
			4'hA: begin
				y = {1'b0, a[7:1]};
				carry_o = a[0];
				sign_o = 1'b0;
				zero_o = ~(| a[7:1]);
			end
			
			4'hB: begin
				y = yora;
				sign_o = yora[7];
				zero_o = ~(| yora);
			end
			
			4'hC: begin
				y = {a[6:0], carry_i};
				carry_o = a[7];
				sign_o = a[6];
				zero_o = ~(| {a[6:0], carry_i});
			end
			
			4'hD: begin
				y = {carry_i, a[7:1]};
				carry_o = a[0];
				sign_o = carry_i;
				zero_o = ~(| {carry_i, a[7:1]});
			end
			
			4'hE: begin
				y = addsub_y;
				addsub_carry_in = ~carry_i;
				add_sub = 1;
				overf_o = (a[7] ^ addsub_y[7]) & (~b[7] ^ addsub_y[7]);
				sign_o = addsub_y[7];
				zero_o = ~(| addsub_y);
				carry_o = addsub_carry_out;
				if (BCD_EN)
					decen = bcden;
			end
			
			4'hF: begin
				y = addsub_y;
				addsub_carry_in = hcarry_i;
				hcarry_o = addsub_carry_out;
			end
		endcase
	end
endmodule
