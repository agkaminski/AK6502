`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:22:24 12/06/2014 
// Design Name: 
// Module Name:    ucode 
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
	//////////////////////////////////////////////////////////
	//	next_sel:											//
	//	0	-	state + 1									//
	//	1	-	int_a										//
	//	2	-	instr_a										//
	//	3	-	amode_a										//
	//////////////////////////////////////////////////////////
	//	const_sel:											//
	//	0	-	00H											//
	//	1	-	01H											//
	//	2	-	FAH											//
	//	3	-	SIGN DIN									//
	//	4	-	FCH											//
	//	6	-	FEH											//
	//	7	-	FFH											//
	//////////////////////////////////////////////////////////
	//	alu_op:												//
	//	0	-	Y = A										//
	// 	1	-	Y = A + B + carry					N,V,Z,C	//
	//	2	-	Y = A AND B						N,Z		//
	//	3	-	Y = {A[6:0],0}, carry = A[7]		N,Z,C	//
	//	4	-	Y = A AND B						N,V,Z	//
	// 	5	-	Y = A - B							N,Z,C	//
	//	6	-	Y = A - 1							N,Z		//
	//	7	-	Y = A + 1							N,Z		//
	// 	8	-	Y = A XOR B						N,Z		//
	//	9	-	Y = A								N,Z		//
	//	A	-	Y = {0,A[7:1]}, carry = A[0]		N,Z,C	//
	//	B	-	Y = A OR B							N,Z		//
	//	C	-	Y = {A[6:0],carry}, carry = A[7]	N,Z,C	//
	//	D	-	Y = {carry,A[7:1]}, carry = A[0]	N,Z,C	//
	//	E	-	Y = A - B - !carry					N,V,Z,C	//
	//	F	-	Y = A + B + hidden carry			HC		//
	//////////////////////////////////////////////////////////
	//	alu_a_mux:											//
	//	0	-	CONST										//
	//	1	-	ACC											//
	//	2	-	XREG										//
	//	3	-	YREG										//
	//	4	-	ABH											//
	//	5	-	PCH											//
	//	6	-	ABL											//
	//	7	-	PCL											//
	//	8	-	SPL											//
	//	9	-	CONST										//
	//	A	-	DATA_I										//
	//	B	-	CONST										//
	//	C	-	PREG										//
	//	X	-	CONST										//
	//////////////////////////////////////////////////////////
	//	alu_b_mux:											//
	//	0	-	CONST										//
	//	1	-	DATA_I										//
	//////////////////////////////////////////////////////////
	//	load_sel:											//
	//	0	-	NO LOAD										//
	//	1	-	ACC											//
	//	2	-	XREG										//
	//	3	-	YREG										//
	//	4	-	ABH											//
	//	5	-	PCH											//
	//	6	-	ABL											//
	//	7	-	PCL											//
	//	8	-	SPL											//
	//	9	-	DATA_O										//
	//	A	-	DATA_I										//
	//	B	-	IREG										//
	//	X	-	NO LOAD										//
	//////////////////////////////////////////////////////////
	//	p_sel:												//
	//	0	-	carry										//
	//	1	-	zero										//
	//	2	-	interrupt mask								//
	//	3	-	decimal										//
	//	4	-	break										//
	//	5	-	X											//
	//	6	-	overflow									//
	//	7	-	negative									//
	//////////////////////////////////////////////////////////
	//	ad_mux:												//
	//	0	-	ADDR = AD_PC								//
	//	1	-	ADDR = AD_AB								//
	//	2	-	ADDR = AD_SP								//
	//	3	-	ADDR = AD_ZP								//
	//////////////////////////////////////////////////////////

module ucode (
	input 		[7:0] 	state,
	output reg 	[1:0] 	next_sel,
	input		[1:0]	register,
	input		[3:0]	decoder_alu_op,
	output 		[28:0] 	control_word
);
	
	localparam SNEXT = 2'b00;
	localparam SINT = 2'b01;
	localparam SSTEP0 = 2'b10;
	localparam SSTEP1 = 2'b11;
	
	localparam CONST_00 = 3'h0;
	localparam CONST_01 = 3'h1;
	localparam CONST_FA = 3'h2;
	localparam CONST_SIGNDIN = 3'h3;
	localparam CONST_FC = 3'h4;
	localparam CONST_FE = 3'h6;
	localparam CONST_FF = 3'h7;
	
	localparam ALU_LOAD = 4'h0;
	localparam ALU_ADC = 4'h1;
	localparam ALU_AND = 4'h2;
	localparam ALU_ASL = 4'h3;
	localparam ALU_BIT = 4'h4;
	localparam ALU_CMP = 4'h5;
	localparam ALU_DEC = 4'h6;
	localparam ALU_INC = 4'h7;
	localparam ALU_EOR = 4'h8;
	localparam ALU_LD = 4'h9;
	localparam ALU_LSR = 4'hA;
	localparam ALU_OR = 4'hB;
	localparam ALU_ROL = 4'hC;
	localparam ALU_ROR = 4'hD;
	localparam ALU_SBC = 4'hE;
	localparam ALU_ISUM = 4'hF;
	
	localparam SEL_CONST = 4'h0;
	localparam SEL_ACC = 4'h1;
	localparam SEL_XREG = 4'h2;
	localparam SEL_YREG = 4'h3;
	localparam SEL_ABH = 4'h4;
	localparam SEL_PCH = 4'h5;
	localparam SEL_ABL = 4'h6;
	localparam SEL_PCL = 4'h7;
	localparam SEL_SPL = 4'h8;
	localparam SEL_DOUT = 4'h9;
	localparam SEL_DIN = 4'hA;
	localparam SEL_IREG = 4'hB;
	localparam SEL_PREG = 4'hC;
	
	localparam SEL_CARRY = 3'h0;
	localparam SEL_ZERO = 3'h1;
	localparam SEL_IEN = 3'h2;
	localparam SEL_DECEN = 3'h3;
	localparam SEL_BREAK = 3'h4;
	localparam SEL_HCARRY = 3'h5;
	localparam SEL_OVERF = 3'h6;
	localparam SEL_NEG = 3'h7;
	
	localparam AD_PC = 2'b00;
	localparam AD_AB = 2'b01;
	localparam AD_SP = 2'b10;
	localparam AD_ZP = 2'b11;

	reg rw;
	reg [2:0] const_sel;
	reg [3:0] alu_op;
	reg [3:0] alu_a;
	reg alu_b;
	reg [3:0] load_sel;
	reg [2:0] p_bit_sel;
	reg p_set;
	reg p_clr;
	reg pc_inc;
	reg spl_inc;
	reg spl_dec;
	reg abh_inc;
	reg [1:0] ad_mux;
	reg nmi_ack;
	reg [3:0] reg_sel;
	
	always @(*) begin
		case (register)
			2'd0: reg_sel = SEL_ACC;
			2'd1: reg_sel = SEL_XREG;
			2'd2: reg_sel = SEL_YREG;
			default: reg_sel = SEL_DIN;
		endcase
	end
		
	assign control_word = { rw, const_sel, alu_op, alu_a, alu_b, load_sel, 
							p_bit_sel, p_set, p_clr, pc_inc, spl_inc,
							spl_dec, abh_inc, ad_mux, nmi_ack };
		
	always @(*) begin
		//defaults
		next_sel 	= SNEXT;
		rw 			= 1;
		const_sel 	= CONST_00;
		alu_op 		= ALU_LOAD;
		alu_a		= SEL_DIN;
		alu_b 		= 0;
		load_sel 	= SEL_CONST;
		p_bit_sel 	= SEL_HCARRY;
		p_set 		= 0;
		p_clr 		= 0;
		pc_inc 		= 0;
		spl_inc 	= 0;
		spl_dec 	= 0;
		abh_inc 	= 0;
		ad_mux 		= AD_AB;
		nmi_ack		= 0;
		
		case (state)
			//RESET
			8'h00:	begin
				p_clr = 1;
			end
			8'h01:;
			8'h02:	begin
				alu_a = SEL_ABL;
				alu_op = ALU_ISUM;
				const_sel = CONST_01;
				load_sel = SEL_ABL;
			end
			8'h03:	begin
				load_sel = SEL_PCL;
				p_clr = 1;
			end
			8'h04:	begin
				p_bit_sel = SEL_IEN;
				p_set = 1;
			end
			8'h05:	begin
				load_sel = SEL_PCH;
			end
			8'h06:	begin
				ad_mux = AD_PC;
			end
			8'h07:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//IRQ
			8'h08:	begin
				ad_mux = AD_SP;
				rw = 0;
			end
			8'h09:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCH;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h0A:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCL;
				load_sel = SEL_DOUT;
				spl_dec = 1;
				rw = 0;
			end
			8'h0B:	begin
				ad_mux = AD_SP;
				alu_a = SEL_CONST;
				const_sel = CONST_FF;
				load_sel = SEL_ABH;
				rw = 0;
			end
			8'h0C:	begin
				ad_mux = AD_SP;
				spl_dec = 1;
				alu_a = SEL_CONST;
				const_sel = CONST_FE;
				load_sel = SEL_ABL;
				p_clr = 1;
				rw = 0;
			end
			8'h0D:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PREG;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h0E:	begin
				spl_dec = 1;
				p_bit_sel = SEL_IEN;
				p_set = 1;
			end
			8'h0F:;
			8'h10:	begin
				alu_a = SEL_ABL;
				const_sel = CONST_01;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h11:	begin
				load_sel = SEL_PCL;
			end
			8'h12:;
			8'h13:	begin
				load_sel = SEL_PCH;
			end
			8'h14:	begin
				ad_mux = AD_PC;
			end
			8'h15:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//NMI
			8'h16:	begin
				ad_mux = AD_SP;
				nmi_ack = 1;
				rw = 0;
			end
			8'h17:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCH;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h18:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCL;
				load_sel = SEL_DOUT;
				spl_dec = 1;
				rw = 0;
			end
			8'h19:	begin
				ad_mux = AD_SP;
				alu_a = SEL_CONST;
				const_sel = CONST_FF;
				load_sel = SEL_ABH;
				rw = 0;
			end
			8'h1A:	begin
				ad_mux = AD_SP;
				spl_dec = 1;
				alu_a = SEL_CONST;
				const_sel = CONST_FA;
				load_sel = SEL_ABL;
				p_clr = 1;
				rw = 0;
			end
			8'h1B:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PREG;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h1C:	begin
				spl_dec = 1;
				p_bit_sel = SEL_IEN;
				p_set = 1;
			end
			8'h1D:;
			8'h1E:	begin
				alu_a = SEL_ABL;
				const_sel = CONST_01;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h1F:	begin
				load_sel = SEL_PCL;
			end
			8'h20:;
			8'h21:	begin
				load_sel = SEL_PCH;
			end
			8'h22:	begin
				ad_mux = AD_PC;
			end
			8'h23:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//OPCODE FETCH
			8'h26:	begin
				ad_mux = AD_PC;
				load_sel = SEL_IREG;
				pc_inc = 1;
			end
			8'h27:	begin
				ad_mux = AD_PC;
				next_sel = SSTEP0;
			end
			
			//absolute
			8'h28:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h29:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABL;
			end
			8'h2A:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h2B:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABH;
			end
			8'h2C:;
			8'h2D:	begin
				next_sel = SSTEP1;
			end
			
			//absolute x
			8'h2E:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
			end
			8'h2F:	begin
				ad_mux = AD_PC;
				alu_a = SEL_XREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h30:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h31:	begin
				ad_mux = AD_PC;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABH;
			end
			8'h32:;
			8'h33:	begin
				next_sel = SSTEP1;
			end
			
			//absolute y
			8'h34:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
			end
			8'h35:	begin
				ad_mux = AD_PC;
				alu_a = SEL_YREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h36:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h37:	begin
				ad_mux = AD_PC;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABH;
			end
			8'h38:;
			8'h39:	begin
				next_sel = SSTEP1;
			end
			
			//zero-page
			8'h3A:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				alu_a = SEL_CONST;
				const_sel = CONST_00;
				load_sel = SEL_ABH;
			end
			8'h3B:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABL;
			end
			8'h3C:;
			8'h3D:	begin
				next_sel = SSTEP1;
			end
			
			//zero-page x
			8'h3E:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
				alu_a = SEL_CONST;
				load_sel = SEL_ABH;
			end
			8'h3F:	begin
				ad_mux = AD_PC;
				alu_a = SEL_XREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h40:;
			8'h41:	begin
				next_sel = SSTEP1;
			end
			
			//zero-page y
			8'h42:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
				alu_a = SEL_CONST;
				load_sel = SEL_ABH;
			end
			8'h43:	begin
				ad_mux = AD_PC;
				alu_a = SEL_YREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h44:;
			8'h45:	begin
				next_sel = SSTEP1;
			end
			
			//indirect x
			8'h46:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
			end
			8'h47:	begin
				ad_mux = AD_PC;
				alu_a = SEL_XREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABH;
			end
			8'h48:	begin
				ad_mux = AD_ZP;
			end
			8'h49:	begin
				ad_mux = AD_ZP;
			end
			8'h4A:	begin
				ad_mux = AD_ZP;
				abh_inc = 1;
			end
			8'h4B:	begin
				ad_mux = AD_ZP;
				load_sel = SEL_ABL;
			end
			8'h4C:	begin
				ad_mux = AD_ZP;
			end
			8'h4D:	begin
				ad_mux = AD_ZP;
				load_sel = SEL_ABH;
			end
			8'h4E:;
			8'h4F:	begin
				next_sel = SSTEP1;
			end
			
			//indirect y
			8'h50:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
				p_clr = 1;
			end
			8'h51:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABH;
			end
			8'h52:	begin
				ad_mux = AD_ZP;
			end
			8'h53:	begin
				ad_mux = AD_ZP;
			end
			8'h54:	begin
				ad_mux = AD_ZP;
				abh_inc = 1;
			end
			8'h55:	begin
				ad_mux = AD_ZP;
				alu_a = SEL_YREG;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h56:	begin
				ad_mux = AD_ZP;
			end
			8'h57:	begin
				ad_mux = AD_ZP;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABH;
			end
			8'h58:;
			8'h59:	begin
				next_sel = SSTEP1;
			end
		
			//ALU OP
			8'h5A:	begin
				ad_mux = AD_PC;
			end
			8'h5B:	begin
				ad_mux = AD_PC;
				alu_a = reg_sel;
				alu_b = 1;
				alu_op = decoder_alu_op;
				load_sel = reg_sel;
				next_sel = SINT;
			end
			
			//ALU OPI
			8'h5C:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h5D:	begin
				ad_mux = AD_PC;
				alu_a = reg_sel;
				alu_b = 1;
				alu_op = decoder_alu_op;
				load_sel = reg_sel;
				next_sel = SINT;
			end

			//ALU MEM
			8'h5E:	begin
				rw = 0;
			end
			8'h5F:	begin
				alu_op = decoder_alu_op;
				alu_a = reg_sel;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h60:	begin
				ad_mux = AD_PC;
			end
			8'h61:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//NBR
			8'h62:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h63:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//BRA
			8'h64:	begin
				pc_inc = 1;
				p_clr = 1;
			end
			8'h65:	begin
				alu_a = SEL_PCL;
				alu_b = 1;
				alu_op = ALU_ISUM;
				load_sel = SEL_PCL;
			end
			8'h66:	begin
				ad_mux = AD_PC;
				alu_a = SEL_PCH;
				const_sel = CONST_SIGNDIN;
				alu_op = ALU_ISUM;
				load_sel = SEL_PCH;
			end
			8'h67:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//BIT
			8'h68:	begin
				ad_mux = AD_PC;
			end
			8'h69:	begin
				ad_mux = AD_PC;
				alu_a = SEL_ACC;
				alu_b = 1;
				alu_op = ALU_BIT;
				next_sel = SINT;
			end
			
			//BRK
			8'h6A:	begin
				ad_mux = AD_SP;
				pc_inc = 1;
				rw = 0;
			end
			8'h6B:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCH;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h6C:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCL;
				load_sel = SEL_DOUT;
				spl_dec = 1;
				rw = 0;
			end
			8'h6D:	begin
				ad_mux = AD_SP;
				alu_a = SEL_CONST;
				const_sel = CONST_FF;
				load_sel = SEL_ABH;
				p_bit_sel = SEL_BREAK;
				p_set = 1;
				rw = 0;
			end
			8'h6E:	begin
				ad_mux = AD_SP;
				spl_dec = 1;
				alu_a = SEL_CONST;
				const_sel = CONST_FE;
				load_sel = SEL_ABL;
				p_clr = 1;
				rw = 0;
			end
			8'h6F:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PREG;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h70:	begin
				spl_dec = 1;
				p_bit_sel = SEL_BREAK;
				p_clr = 1;
			end
			8'h71:;
			8'h72:	begin
				alu_a = SEL_ABL;
				const_sel = CONST_01;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h73:	begin
				load_sel = SEL_PCL;
			end
			8'h74:	begin
				p_bit_sel = SEL_IEN;
				p_set = 1;
			end
			8'h75:	begin
				ad_mux = AD_PC;
				load_sel = SEL_PCH;
			end
			8'h76:	begin
				ad_mux = AD_PC;
			end
			8'h77:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//CLC
			8'h78:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_CARRY;
				p_clr = 1;
			end
			8'h79:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//CLD
			8'h7A:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_DECEN;
				p_clr = 1;
			end
			8'h7B:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//CLI
			8'h7C:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_IEN;
				p_clr = 1;
			end
			8'h7D:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//CLV
			8'h7E:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_OVERF;
				p_clr = 1;
			end
			8'h7F:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
				
			//CMP
			8'h80:	begin
				ad_mux = AD_PC;
			end
			8'h81:	begin
				ad_mux = AD_PC;
				alu_a = reg_sel;
				alu_b = 1;
				alu_op = ALU_CMP;
				next_sel = SINT;
			end
			
			//CMPI
			8'h82:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h83:	begin
				ad_mux = AD_PC;
				alu_a = reg_sel;
				alu_b = 1;
				alu_op = ALU_CMP;
				next_sel = SINT;
			end
			
			//JMPA
			8'h84:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h85:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABL;
			end
			8'h86:	begin
				alu_a = SEL_ABL;
				load_sel = SEL_PCL;
			end
			8'h87:	begin
				load_sel = SEL_PCH;
			end
			8'h88:	begin
				ad_mux = AD_PC;
			end
			8'h89:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//JMPI
			8'h8A:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'h8B:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABL;
			end
			8'h8C:	begin
				ad_mux = AD_PC;
			end
			8'h8D:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABH;
				p_clr = 1;
			end
			8'h8E:;
			8'h8F:;
			8'h90:	begin
				alu_a = SEL_ABL;
				const_sel = CONST_01;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABL;
			end
			8'h91:	begin
				load_sel = SEL_PCL;
			end
			8'h92:	begin
				alu_a = SEL_ABH;
				alu_op = ALU_ISUM;
				load_sel = SEL_ABH;
			end
			8'h93:;
			8'h94:;
			8'h95:	begin
				ad_mux = AD_PC;
				load_sel = SEL_PCH;
			end
			8'h96:	begin
				ad_mux = AD_PC;
			end
			8'h97:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//JSR
			8'h98:	begin
				ad_mux = AD_SP;
				rw = 0;
			end
			8'h99:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCH;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h9A:	begin
				ad_mux = AD_SP;
				alu_a = SEL_ABH;
				load_sel = SEL_PCH;
				spl_dec = 1;
				rw = 0;
			end
			8'h9B:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PCL;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'h9C:	begin
				ad_mux = AD_PC;
				alu_a = SEL_ABL;
				load_sel = SEL_PCL;
				spl_dec = 1;
			end
			8'h9D:	begin	
				ad_mux = AD_PC;
				next_sel = SINT;
			end

			//NOP
			8'h9E:	begin
				ad_mux = AD_PC;
			end
			8'h9F:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//PHA
			8'hA0:	begin
				ad_mux = AD_SP;
				rw = 0;
			end
			8'hA1:	begin
				ad_mux = AD_SP;
				alu_a = SEL_ACC;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'hA2:	begin
				ad_mux = AD_PC;
				spl_dec = 1;
			end
			8'hA3:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//PHP
			8'hA4:	begin
				ad_mux = AD_SP;
				p_clr = 1;
				rw = 0;
				p_bit_sel = SEL_BREAK;
				p_set = 1;
			end
			8'hA5:	begin
				ad_mux = AD_SP;
				alu_a = SEL_PREG;
				load_sel = SEL_DOUT;
				rw = 0;
			end
			8'hA6:	begin
				ad_mux = AD_PC;
				spl_dec = 1;
				p_bit_sel = SEL_BREAK;
				p_clr = 1;
			end
			8'hA7:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//PLA
			8'hA8:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hA9:	begin
				ad_mux = AD_SP;
			end
			8'hAA:	begin
				ad_mux = AD_PC;
			end
			8'hAB:	begin
				ad_mux = AD_PC;
				alu_op = ALU_LD;
				load_sel = SEL_ACC;
				next_sel = SINT;
			end
			
			//PLP
			8'hAC:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hAD:	begin
				ad_mux = AD_SP;
			end
			8'hAE:	begin
				ad_mux = AD_PC;
			end
			8'hAF:	begin
				ad_mux = AD_PC;
				load_sel = SEL_PREG;
			end
			8'hB0:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_BREAK;
				p_clr = 1;
			end
			9'hB1:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//RTI
			8'hB2:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hB3:	begin
				ad_mux = AD_SP;
			end
			8'hB4:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hB5:	begin
				ad_mux = AD_SP;
				load_sel = SEL_PREG;
			end
			8'hB6:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
				p_bit_sel = SEL_BREAK;
				p_clr = 1;
				spl_inc = 1;
			end
			8'hB7:	begin
				ad_mux = AD_SP;
				load_sel = SEL_PCL;
			end
			8'hB8:	begin
				ad_mux = AD_SP;
			end
			8'hB9:	begin
				ad_mux = AD_SP;
				load_sel = SEL_PCH;
			end
			8'hBA:	begin
				ad_mux = AD_PC;
			end
			8'hBB:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//RTS
			8'hBC:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hBD:	begin
				ad_mux = AD_SP;
			end
			8'hBE:	begin
				ad_mux = AD_SP;
				spl_inc = 1;
			end
			8'hBF:	begin
				ad_mux = AD_SP;
				load_sel = SEL_PCL;
			end
			8'hC0:	begin
				ad_mux = AD_SP;
			end
			8'hC1:	begin
				ad_mux = AD_SP;
				load_sel = SEL_PCH;
			end
			8'hC2:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'hC3:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//SEC
			8'hC4:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_CARRY;
				p_set = 1;
			end
			8'hC5:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//SED
			8'hC6:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_DECEN;
				p_set = 1;
			end
			8'hC7:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//SEI
			8'hC8:	begin
				ad_mux = AD_PC;
				p_bit_sel = SEL_IEN;
				p_set = 1;
			end
			8'hC9:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TAX
			8'hCA:	begin
				ad_mux = AD_PC;
				alu_a = SEL_ACC;
				alu_op = ALU_LD;
				load_sel = SEL_XREG;
			end
			8'hCB:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TAY
			8'hCC:	begin
				ad_mux = AD_PC;
				alu_a = SEL_ACC;
				alu_op = ALU_LD;
				load_sel = SEL_YREG;
			end
			8'hCD:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TSX
			8'hCE:	begin
				ad_mux = AD_PC;
				alu_a = SEL_SPL;
				alu_op = ALU_LD;
				load_sel = SEL_XREG;
			end
			8'hCF:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TXA
			8'hD0:	begin
				ad_mux = AD_PC;
				alu_a = SEL_XREG;
				alu_op = ALU_LD;
				load_sel = SEL_ACC;
			end
			8'hD1:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TXS
			8'hD2:	begin
				ad_mux = AD_PC;
				alu_a = SEL_XREG;
				alu_op = ALU_LOAD;
				load_sel = SEL_SPL;
			end
			8'hD3:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//TYA
			8'hD4:	begin
				ad_mux = AD_PC;
				alu_a = SEL_YREG;
				alu_op = ALU_LD;
				load_sel = SEL_ACC;
			end
			8'hD5:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
			//BRA WAIT
			8'hD6:	begin
				ad_mux = AD_PC;
			end
			8'hD7:	begin
				ad_mux = AD_PC;
				next_sel = SSTEP1;
			end
			
			//ALU LOADI
			8'hD8:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'hD9:	begin
				ad_mux = AD_PC;
				alu_a = SEL_DIN;
				alu_b = 1;
				alu_op = decoder_alu_op;
				load_sel = reg_sel;
				next_sel = SINT;
			end
			
			//ALU LOAD
			8'hDA:	begin
				ad_mux = AD_PC;
			end
			8'hDB:	begin
				ad_mux = AD_PC;
				alu_a = SEL_DIN;
				alu_b = 1;
				alu_op = decoder_alu_op;
				load_sel = reg_sel;
				next_sel = SINT;
			end
			
			//absolute no inc
			8'hDC:	begin
				ad_mux = AD_PC;
				pc_inc = 1;
			end
			8'hDD:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABL;
			end
			8'hDE:	begin
				ad_mux = AD_PC;
			end
			8'hDF:	begin
				ad_mux = AD_PC;
				load_sel = SEL_ABH;
			end
			8'hE0:;
			8'hE1:	begin
				next_sel = SSTEP1;
			end
			
			default:	begin
				ad_mux = AD_PC;
				next_sel = SINT;
			end
			
		endcase
	end	
endmodule