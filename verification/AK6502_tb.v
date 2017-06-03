`timescale 1ns / 1ps

module AK6502_tb();
	reg clk;
	reg rst_n;
	wire rw;
	wire ph2;
	wire sync;
	wire [15:0] address;
	wire [7:0] data_i;
	wire [7:0] data_o;
	
	initial begin
		$dumpfile("waveform.vcd");
    		$dumpvars(0,AK6502_tb);
		clk = 0;
		rst_n = 0;
		#10 rst_n = 1;
		
		forever #1 clk = !clk;
	end
	
	
	always @(posedge clk) begin
		if (ph2 && sync)
			$display("I %H PC %H P %H A %H X %H Y %H SP %H", data_i, address, uut.preg, uut.acc, uut.xreg, uut.yreg, uut.spl);
		else if (ph2 && ~rw)
			$display("W %H @ %h", data_o, address);
		else if (ph2)
			$display("R %H @ %h", data_i, address);
			
//		if (uut.u_control_unit.state == 8'h65 && uut.din == 8'hFE)
//			$stop();
	end

	ram uram (
		.clk		(clk),
		.rst_n		(rst_n),
		.addr		(address),
		.din		(data_o),
		.dout		(data_i),
		.rw			(rw),
		.en			(ph2)
	);
	
	
	AK6502 uut (
		.clk		(clk),
		.clk_en		(1'b1),
		.rst_n		(rst_n),
		.irq_n		(1'b1),
		.nmi_n		(1'b1),
		.so_n		(1'b1),
		.ready		(1'b1),
		.rw			(rw),
		.ph2		(ph2),
		.sync		(sync),
		.address	(address),
		.data_i		(data_i),
		.data_o		(data_o)
	);

endmodule
