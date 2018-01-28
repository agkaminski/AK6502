`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:06:47 12/05/2014 
// Design Name: 
// Module Name:    AK6502 
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
module AK6502 #(parameter BCD_EN = 1)
(
	input clk,
	input clk_en,
	input rst_n,
	input irq_n,
	input nmi_n,
	input so_n,
	input ready,
	output rw,
	output ph2,
	output sync,
	output reg [15:0] address,
	input [7:0] data_i,
	output [7:0] data_o
);

	reg clk_en_i;
	
	//registers
	reg [7:0] acc;
	reg [7:0] xreg;
	reg [7:0] yreg;
	reg [15:0] ab;
	reg [15:0] pc;
	reg [7:0] spl;
	reg [7:0] din;
	reg [7:0] dout;
	reg [7:0] ireg;
	
	reg [7:0] preg;
	
	reg [7:0] const_table;
	wire [2:0] const_sel;
	
	//alu/bus signals
	reg [7:0] alu_a;
	reg [7:0] alu_b;
	wire [7:0] alu_y;
	wire [7:0] alu_flags_o;
	wire [3:0] alu_op;
	
	wire [3:0] alu_a_mux;
	wire alu_b_mux;
	
	//preg load signals
	wire alu_p_load;
	
	wire [2:0] p_bit_sel;
	wire p_set;
	wire p_clr;
	
	//register inc/dec signals
	wire pc_inc;
	wire spl_inc;
	wire spl_dec;
	wire abh_inc;
	
	//address mux signals
	wire [1:0] ad_mux;
	reg [1:0] ad_mux_b;
	
	wire [3:0] load_sel;
	
	//interrupt buffers signals
	wire nmi_ack;
	reg nmi_i;
	reg nmi_c;
	reg irq_i;
	reg so_i;
	
	//clock enable control
	always @(*) begin
		if (~clk_en || (ph2 && ~ready))
			clk_en_i = 0;
		else
			clk_en_i = 1;
	end
	
	//registers load control
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			acc <= 8'h00;
			xreg <= 8'h00;
			yreg <= 8'h00;
			ab <= 16'hFFFC;
			pc <= 16'hFFFC;
			spl <= 8'hFF;
			din <= 8'h00;
			dout <= 8'h00;
			ireg <= 8'h00;
			preg <= 8'h04;
		end else if (clk_en_i) begin
			case(load_sel)
				4'h1:	acc <= alu_y;
				4'h2:	xreg <= alu_y;
				4'h3:	yreg <= alu_y;
				4'h4:	ab[15:8] <= alu_y;
				4'h5:	pc[15:8] <= alu_y;
				4'h6:	ab[7:0] <= alu_y;
				4'h7:	pc[7:0] <= alu_y;
				4'h8:	spl <= alu_y;
				4'h9:	dout <= alu_y;
				4'hB:	ireg <= data_i;
				4'hC:	preg <= alu_y;
				default:;
			endcase
			
			//data in loaded on every ph2 falling egde
			if (ph2)
				din <= data_i;
			
			if (pc_inc)
				pc <= pc + 1;
			if (abh_inc)
				ab[15:8] <= ab[15:8] + 1;
			if (spl_inc)
				spl <= spl + 1;
			else if (spl_dec)
				spl <= spl - 1;
				
			if (alu_p_load)
				preg <= alu_flags_o;
			else if (p_set | p_clr) begin
				case (p_bit_sel)
					3'b000:	preg[0] <= p_set;
					3'b001:	preg[1] <= p_set;
					3'b010:	preg[2] <= p_set;
					3'b011:	preg[3] <= p_set;
					3'b100:	preg[4] <= p_set;
					3'b101:	preg[5] <= p_set;
					3'b110:	preg[6] <= p_set;
					3'b111:	preg[7] <= p_set;
				endcase
			end
			
			if (~so_i)
				preg[7] <= 1;
		end
	end
	
	//nmi egde trigger & buffer
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			nmi_i <= 1;
			nmi_c <= 0;
		end else if (clk_en_i) begin
			if (nmi_n)
				nmi_c <= 1;
			else if (nmi_c) begin
				nmi_i <= 0;
				nmi_c <= 0;
			end
			
			if (nmi_ack)
				nmi_i <= 1;
		end
	end
	
	//irq buffer
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			irq_i <= 1;
		else if (clk_en_i)
			irq_i <= irq_n;
	end
	
	//so buffer
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			so_i <= 1;
		else if (clk_en_i)
			so_i <= so_n;
	end
	
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			ad_mux_b <= 2'b01;
		else if (clk_en_i)
			ad_mux_b <= ad_mux;
	end
	
	//control unit instance
	control_unit	u_control_unit
	(
		.clk		(clk),
		.clk_en		(clk_en_i),
		.rst_n		(rst_n),
		.irq_n		(irq_i),
		.nmi_n		(nmi_i),
		.preg		(preg),
		.ireg		(ireg),
		.nmi_ack	(nmi_ack),
		.rw			(rw),
		.ph2		(ph2),
		.sync		(sync),
		.const_sel	(const_sel),
		.alu_op		(alu_op),
		.alu_a_mux	(alu_a_mux),
		.alu_b_mux	(alu_b_mux),
		.load_sel	(load_sel),
		.p_bit_sel	(p_bit_sel),
		.p_set		(p_set),
		.p_clr		(p_clr),
		.pc_inc		(pc_inc),
		.spl_inc	(spl_inc),
		.spl_dec	(spl_dec),
		.abh_inc	(abh_inc),
		.ad_mux		(ad_mux)
	);
	
	//ALU instance
	alu	#(BCD_EN)	u_alu
	(
		.a			(alu_a),
		.b			(alu_b),
		.y			(alu_y),
		.flags_i	(preg),
		.flags_o	(alu_flags_o),
		.p_load		(alu_p_load),
		.alu_op		(alu_op)
	);
	
	assign data_o = dout;
	
	//constans table
	always @(*) begin
		case (const_sel)
			3'b000:		const_table = 8'h00;
			3'b001:		const_table = 8'h01;
			3'b010:		const_table = 8'hFA;
			3'b011:		const_table = {8{din[7]}};
			3'b100:		const_table = 8'hFC;
			3'b110:		const_table = 8'hFE;
			3'b111:		const_table = 8'hFF;
			default:	const_table = 8'bx;
		endcase
	end
	
	//ALU A bus mux
	always @(*) begin
		case (alu_a_mux)
			4'h1:		alu_a = acc;
			4'h2:		alu_a = xreg;
			4'h3:		alu_a = yreg;
			4'h4:		alu_a = ab[15:8];
			4'h5:		alu_a = pc[15:8];
			4'h6:		alu_a = ab[7:0];
			4'h7:		alu_a = pc[7:0];
			4'h8:		alu_a = spl;
			4'hA:		alu_a = din;
			4'hC:		alu_a = preg | 8'h20;
			default:	alu_a = const_table;
		endcase
	end
	
	//ALU B bus mux
	always @(*) begin
		case (alu_b_mux)
			1'b0:		alu_b = const_table;
			1'b1:		alu_b = din;
		endcase
	end
	
	//address muxs
	always @(*) begin
		case (ad_mux_b)
			2'b00:		address = pc;
			2'b01:		address = ab;
			2'b10:		address = { 8'h01, spl };
			default:	address = { 8'h00, ab[15:8] };
		endcase
	end

endmodule
