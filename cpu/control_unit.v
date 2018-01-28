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
		output reg [3:0] alu_op,
		output reg [3:0] alu_a_mux,
		output alu_b_mux,
		output reg [3:0] load_sel,
		output [2:0] p_bit_sel,
		output p_set,
		output p_clr,
		output pc_inc,
		output spl_inc,
		output spl_dec,
		output abh_inc,
		output [1:0] ad_mux
	);
	
	reg  [7:0] 	addr;
	reg  [7:0] 	addr_next;
	reg			branch;
	wire [1:0] 	next_sel;
	reg  [3:0]  reg_sel;
	wire [3:0]  alu_a_mux_i;
	wire [3:0]  load_sel_i;
	wire [4:0]  alu_op_i;
	
	wire [7:0] 	step0_a;
	wire [7:0] 	step1_a;
	wire [7:0] 	int_a;
	wire [1:0] 	register;
	wire [3:0] 	decoder_alu_op;
	
	wire [31:0] control_word;
	wire rw_i;
	
	assign ph2 = ~addr[0];
	assign {	rw_i, const_sel, alu_op_i, alu_a_mux_i, alu_b_mux,
				load_sel_i, p_bit_sel, p_set, p_clr, pc_inc, spl_inc,
				spl_dec, abh_inc, ad_mux, nmi_ack, next_sel } = control_word;
	
	always @(posedge clk, negedge rst_n)	begin
		if (~rst_n)
			sync <= 1;
		else if (clk_en) begin
			if(addr_next[7:1] == 8'h13)
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
			2'b00:		addr_next = addr + 1;
			2'b01:		addr_next = int_a;
			2'b10:		addr_next = step0_a;
			2'b11:		addr_next = step1_a;
			default:	addr_next = int_a;
		endcase
	end
	
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			addr <= 0;
		else if (clk_en)
			addr <= addr_next;
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
	
	always @(*) begin
		case (register)
			2'd0: reg_sel = 4'h1;
			2'd1: reg_sel = 4'h2;
			2'd2: reg_sel = 4'h3;
			default: reg_sel = 4'hA;
		endcase
	end
	
	always @(*) begin
		if (alu_a_mux_i == 4'hF)
			alu_a_mux = reg_sel;
		else
			alu_a_mux = alu_a_mux_i;
			
		if (load_sel_i == 4'hF)
			load_sel = reg_sel;
		else
			load_sel = load_sel_i;
	
		if (alu_op_i[4])
			alu_op <= decoder_alu_op;
		else
			alu_op <= alu_op_i[3:0];
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
		.addr			(addr),
		.control_word	(control_word)
	);

endmodule
