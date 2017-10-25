`timescale 1ns/1ps

module AK6551
(
	input clk,
	input clk_en,
	input rst_n;
	input [1:0] rs;
	input cs_n,
	input rw,
	input en,
	input [7:0] din,
	output reg [7:0] dout,
	output irq_n,
	input txd,
	output rxd,
	output rst_n,
	input cts_n,
	output dtr_n,
	input dsr_n,
	input dcd_n
);

	reg [7:0] txdata;
	reg [7:0] rxdata;
	reg [7:0] status;
	reg [7:0] command;
	reg [7:0] control;

	reg txd_trigger;
	reg rst_trigger;

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			txdata <= 8'h0;
			rxdata <= 8'h0;
			status <= 8'h0;
			command <= 8'h0;
			control <= 8'h0;
			dout <= 8'h0;
			txd_trigger <= 0;
			rst_trigger <= 0;
		end else if (clk_en) begin
			txd_trigger <= 0;
			rst_trigger <= 0;

			if (~cs_n && ~rw && en) begin
				case (rs) begin
					2'b00: begin
						txdata <= din;
						txd_trigger <= 1;
					end
					2'b01: rst_trigger <= 1;
					2'b10: command <= din;
					default: control <= din;
				endcase
			end

			case (rs) begin
				2'b00: dout <= rxdata;
				2'b01: dout <= status;
				2'b10: dout <= command;
				default: dout <= control;
			endcase
		end
	end



endmodule

