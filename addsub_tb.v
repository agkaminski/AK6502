`timescale 1ns / 1ps

module addsub_tb ();

	function [8:0] bcd_add;
		input [7:0] a, b;
		input c;
		reg [8:0] res;
		reg [4:0] low;
		begin
			res = a + b + c;
			low = a[3:0] + b[3:0] + c;
			
			if ((res[3:0] > 9) || low[4])
				res = res + 8'h06;
			if (res[7:4] > 9 || res[8])
				res = res + 8'h60;
				
			bcd_add = res;
		end
	endfunction
	
	function [8:0] bcd_sub;
		input [7:0] a, b;
		input c;
		reg [8:0] low;
		reg [8:0] high;
		reg [7:0] bi;
		
		begin
			bi = 8'h99 - b;
			high = a[3:0] + bi[3:0] + c;
			
			low = a + bi + c;
			if (low[3:0] > 9 || high[4])
				low = low + 8'h06;
			if (low[7:4] > 9 || low[8])
				low = low + 8'h60;
				
			bcd_sub = low;
		end
	endfunction
			

	reg [7:0] a;
	reg [7:0] b;
	wire [7:0] y;
	reg add_sub;
	reg decen;
	reg carry_in;
	wire carry_out;
	
	reg clk;
	
	integer i;
	integer j;
	integer res;
	reg [8:0] expected;
	
	initial begin
		clk = 0;
		forever #1 clk = ~clk;
	end
	
	always @(clk) begin
		//binary add test
		add_sub = 0;
		decen = 0;
		carry_in = 0;
		for (i = 0; i < 256; i = i + 1) begin
			for (j = 0; j < 256; j = j + 1) begin
				wait (clk == 0);
				a = i;
				b = j;
				res = i + j + carry_in;
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("Binary add, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Result error y = %d expected %d", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("Binary add, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//binary add + carry test
		add_sub = 0;
		decen = 0;
		carry_in = 1;
		for (i = 0; i < 256; i = i + 1) begin
			for (j = 0; j < 256; j = j + 1) begin
				wait (clk == 0);
				a = i;
				b = j;
				res = i + j + carry_in;
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("Binary add, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Result error y = %d expected %d", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("Binary add, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//binary sub test
		add_sub = 1;
		decen = 0;
		carry_in = 0;
		for (i = 0; i < 256; i = i + 1) begin
			for (j = 0; j < 256; j = j + 1) begin
				wait (clk == 0);
				a = i;
				b = j;
				res = i - j - carry_in;
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("Binary sub, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Result error y = %d expected %d", y, expected[7:0]);
					$finish();
				end
				else if (carry_out == expected[8]) begin
					$display("Binary sub, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//binary sub + carry test
		add_sub = 1;
		decen = 0;
		carry_in = 1;
		for (i = 0; i < 256; i = i + 1) begin
			for (j = 0; j < 256; j = j + 1) begin
				wait (clk == 0);
				a = i;
				b = j;
				res = i - j - carry_in;
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("Binary sub, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Result error y = %d expected %d", y, expected[7:0]);
					$finish();
				end
				else if (carry_out == expected[8]) begin
					$display("Binary sub, carry_in = %d a = %d b = %d y = %d", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		
		
		
		//bcd add test
		add_sub = 0;
		decen = 1;
		carry_in = 0;
		for (i = 0; i <= 8'h99; i = i + 1) begin
			for (j = 0; j <= 8'h99; j = j + 1) begin
				if (i[3:0] > 9)
					i = i + 6;
				if (i[7:4] > 9)
					i = i + 8'h60;
				if (j[3:0] > 9)
					j = j + 6;
				if (i[7:4] > 9)
					j = j + 8'h60;
				wait (clk == 0);
				a = i;
				b = j;
				res = bcd_add(i, j, carry_in);
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("bcd add, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Result error y = %h expected %h", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("bcd add, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//bcd add + carry test
		add_sub = 0;
		decen = 1;
		carry_in = 1;
		for (i = 0; i <= 8'h99; i = i + 1) begin
			for (j = 0; j <= 8'h99; j = j + 1) begin
				if (i[3:0] > 9)
					i = i + 6;
				if (i[7:4] > 9)
					i = i + 8'h60;
				if (j[3:0] > 9)
					j = j + 6;
				if (i[7:4] > 9)
					j = j + 8'h60;
				wait (clk == 0);
				a = i;
				b = j;
				res = bcd_add(i, j, carry_in);
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("bcd add, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Result error y = %h expected %h", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("bcd add, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//bcd sub test
		add_sub = 1;
		decen = 1;
		carry_in = 0;
		for (i = 0; i <= 8'h99; i = i + 1) begin
			for (j = 0; j <= 8'h99; j = j + 1) begin
				if (i[3:0] > 9)
					i = i + 6;
				if (i[7:4] > 9)
					i = i + 8'h60;
				if (j[3:0] > 9)
					j = j + 6;
				if (i[7:4] > 9)
					j = j + 8'h60;
				wait (clk == 0);
				a = i;
				b = j;
				res = bcd_sub(i, j, carry_in);
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("bcd sub, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Result error y = %h expected %h", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("bcd sub, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		//bcd sub + carry test
		add_sub = 1;
		decen = 1;
		carry_in = 1;
		for (i = 0; i <= 8'h99; i = i + 1) begin
			for (j = 0; j <= 8'h99; j = j + 1) begin
				if (i[3:0] > 9)
					i = i + 6;
				if (i[7:4] > 9)
					i = i + 8'h60;
				if (j[3:0] > 9)
					j = j + 6;
				if (i[7:4] > 9)
					j = j + 8'h60;
				wait (clk == 0);
				a = i;
				b = j;
				res = bcd_sub(i, j, carry_in);
				
				expected = res[8:0];
				wait (clk == 1);
				
				if (y != expected[7:0]) begin
					$display("bcd sub, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Result error y = %h expected %h", y, expected[7:0]);
					$finish();
				end
				else if (carry_out != expected[8]) begin
					$display("bcd sub, carry_in = %d a = %h b = %h y = %h", carry_in, a, b, y);
					$display("Carry error c = %d expected %d", carry_out, expected[8]);
					$finish();
				end
			end
		end
		
		$display("Success");
		$finish();
	end
			
	
	addsub UUT (
		.a			(a),
		.b			(b),
		.y			(y),
		.add_sub	(add_sub),
		.decen		(decen),
		.carry_in	(carry_in),
		.carry_out	(carry_out)
	);


endmodule
