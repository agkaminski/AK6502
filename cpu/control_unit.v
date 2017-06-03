`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:35:03 12/05/2014 
// Design Name: 
// Module Name:    control_unit 
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
module control_unit
	(
		input clk,
		input clk_en,
		input rst_n,
		input irq_n,
		input nmi_n,
		input [7:0] preg,
		input [7:0] ireg,
		output nmi_ack,
		output reg rw,
		output ph2,
		output reg sync,
		output [2:0] const_sel,
		output [3:0] alu_op,
		output [3:0] alu_a_mux,
		output alu_b_mux,
		output [3:0] load_sel,
		output [2:0] p_bit_sel,
		output p_set,
		output p_clr,
		output pc_inc,
		output spl_inc,
		output spl_dec,
		output abh_inc,
		output [1:0] ad_mux
	);
	
	reg  [7:0] 	state;
	reg  [7:0] 	state_next;
	reg			branch;
	wire [1:0] 	next_sel;
	
	wire [7:0] 	step0_a;
	wire [7:0] 	step1_a;
	wire [7:0] 	int_a;
	wire [1:0] 	register;
	wire [3:0] 	decoder_alu_op;
	
	wire [28:0] control_word;
	wire rw_i;
	
	assign ph2 = ~state[0];
	assign {	rw_i, const_sel, alu_op, alu_a_mux, alu_b_mux,
				load_sel, p_bit_sel, p_set, p_clr, pc_inc, spl_inc,
				spl_dec, abh_inc, ad_mux, nmi_ack } = control_word;
	
	always @(posedge clk, negedge rst_n)	begin
		if (~rst_n)
			sync <= 1;
		else if (clk_en) begin
			if(state_next[7:1] == 8'h13)
				sync <= 1;
			else
				sync <= 0;
		end
	end	
				
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			rw <= 1;
		else if (clk_en)
			rw <= rw_i;
	end
	
	always @(*) begin
		case (next_sel)
			2'b00:		state_next = state + 1;
			2'b01:		state_next = int_a;
			2'b10:		state_next = step0_a;
			2'b11:		state_next = step1_a;
			default:	state_next = int_a;
		endcase
	end
	
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			state <= 0;
		else if (clk_en)
			state <= state_next;
	end
	
	//branch control
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			branch <= 0;
		else if(clk_en) begin
			case (ireg[7:6])
				2'b00:	branch <= ~(preg[7]^ireg[5]);		//negative
				2'b01:	branch <= ~(preg[6]^ireg[5]);		//overflow
				2'b10:	branch <= ~(preg[0]^ireg[5]);		//carry
				2'b11:	branch <= ~(preg[1]^ireg[5]);		//zero
			endcase
		end
	end
	
	opdecoder	u_opdecoder
	(
		.irq_n			(irq_n),
		.nmi_n			(nmi_n),
		.branch			(branch),
		.irqen			(~preg[2]),
		.ireg			(ireg),
		.step0_a		(step0_a),
		.step1_a		(step1_a),
		.int_a			(int_a),
		.register		(register),
		.alu_op			(decoder_alu_op)
	);
	
	ucode		u_ucode
	(
		.state			(state),
		.next_sel		(next_sel),
		.register		(register),
		.decoder_alu_op (decoder_alu_op),
		.control_word	(control_word)
	);

endmodule
