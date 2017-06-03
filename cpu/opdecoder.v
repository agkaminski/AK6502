`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:12:50 12/06/2014 
// Design Name: 
// Module Name:    i_decoder 
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
module opdecoder (
	input				irq_n,
	input				nmi_n,
	input				branch,
	input				irqen,
	input		[7:0]	ireg,
	output		[7:0]	step0_a,
	output		[7:0]	step1_a,
	output		[7:0]	int_a,
	output reg	[1:0]	register,
	output reg	[3:0]	alu_op
);
	reg [6:0] step0;
	reg [6:0] step1;
	reg [6:0] int_i;
	
	//instructions
	localparam ALUOP 	= 7'h2D;
	localparam ALUOPI 	= 7'h2E;
	localparam ALUMEM 	= 7'h2F;
	localparam ALULOAD	= 7'h6D;
	localparam ALULOADI	= 7'h6C;
	localparam WBR 		= 7'h6B;
	localparam NBR 		= 7'h31;
	localparam BRA 		= 7'h32;
	localparam BIT 		= 7'h34;
	localparam BRK 		= 7'h35;
	localparam CLC 		= 7'h3C;
	localparam CLD 		= 7'h3D;
	localparam CLI 		= 7'h3E;
	localparam CLV 		= 7'h3F;
	localparam CMP 		= 7'h40;
	localparam CMPI 	= 7'h41;
	localparam JMPA 	= 7'h42;
	localparam JMPI 	= 7'h45;
	localparam JSR 		= 7'h4C;
	localparam NOP 		= 7'h4F;
	localparam PHA 		= 7'h50;
	localparam PHP 		= 7'h52;
	localparam PLA 		= 7'h54;
	localparam PLP 		= 7'h56;
	localparam RTI 		= 7'h59;
	localparam RTS 		= 7'h5E;
	localparam SEC 		= 7'h62;
	localparam SED 		= 7'h63;
	localparam SEI 		= 7'h64;
	localparam TAX 		= 7'h65;
	localparam TAY 		= 7'h66;
	localparam TSX 		= 7'h67;
	localparam TXA 		= 7'h68;
	localparam TXS 		= 7'h69;
	localparam TYA 		= 7'h6A;
	
	//addressing modes
	localparam AABS 	= 7'h14;		//absolute
	localparam AABSNINC	= 7'h6E;		//absolute no inc
	localparam AABX 	= 7'h17;		//absolute indexed X
	localparam AABY 	= 7'h1A;		//absolute indexed Y
	localparam AZEP 	= 7'h1D;		//zero-page
	localparam AZPX 	= 7'h1F;		//zero-page indexed X
	localparam AZPY 	= 7'h21;		//zero-page indexed Y
	localparam AINX 	= 7'h23;		//indexed X indirect
	localparam AINY 	= 7'h28;		//indexed Y indirect
	
	//interrups etc
	localparam IOPC 	= 7'h13;
	localparam IIRQ 	= 7'h04;
	localparam INMI 	= 7'h0B;
	
	//registers
	localparam REGACC 	= 2'd0;
	localparam REGX 	= 2'd1;
	localparam REGY 	= 2'd2;
	localparam REGDIN 	= 2'd3;
	
	//ALU operations
	localparam ALU_LOAD = 4'h0;
	localparam ALU_ADC 	= 4'h1;
	localparam ALU_AND 	= 4'h2;
	localparam ALU_ASL 	= 4'h3;
	localparam ALU_BIT 	= 4'h4;
	localparam ALU_CMP 	= 4'h5;
	localparam ALU_DEC 	= 4'h6;
	localparam ALU_INC 	= 4'h7;
	localparam ALU_EOR 	= 4'h8;
	localparam ALU_LD 	= 4'h9;
	localparam ALU_LSR 	= 4'hA;
	localparam ALU_OR 	= 4'hB;
	localparam ALU_ROL 	= 4'hC;
	localparam ALU_ROR 	= 4'hD;
	localparam ALU_SBC 	= 4'hE;
	localparam ALU_ISUM = 4'hF;
	
	//decoded step is multiplied by 2
	assign step0_a = {step0, 1'b0};
	assign step1_a = {step1, 1'b0};
	assign int_a = {int_i, 1'b0};
	
	//instruction decoding in to two stages
	always @(*) begin
		register = REGACC;
		alu_op = ALU_LOAD;
	
		case (ireg)
			8'h00:	begin
				step0 = BRK;
				step1 = NOP;
			end
			8'h01:	begin
				step0 = AINX;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h05:	begin
				step0 = AZEP;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h06:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ASL;
			end
			8'h08:	begin
				step0 = PHP;
				step1 = NOP;
			end
			8'h09:	begin
				step0 = ALUOPI;
				step1 = NOP;
				alu_op = ALU_OR;
			end
			8'h0A:	begin
				step0 = ALUOP;
				step1 = NOP;
				alu_op = ALU_ASL;
			end
			8'h0D:	begin
				step0 = AABS;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h0E:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ASL;
			end
			
			
			8'h10:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'h11:	begin
				step0 = AINY;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h15:	begin
				step0 = AZPX;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h16:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ASL;
			end
			8'h18:	begin
				step0 = CLC;
				step1 = NOP;
			end
			8'h19:	begin
				step0 = AABY;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h1D:	begin
				step0 = AABX;
				step1 = ALUOP;
				alu_op = ALU_OR;
			end
			8'h1E:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ASL;
			end
			
			
			8'h20:	begin
				step0 = AABSNINC;
				step1 = JSR;
			end
			8'h21:	begin
				step0 = AINX;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h24:	begin
				step0 = AZEP;
				step1 = BIT;
			end
			8'h25:	begin
				step0 = AZEP;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h26:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROL;
			end
			8'h28:	begin
				step0 = PLP;
				step1 = NOP;
			end
			8'h29:	begin
				step0 = ALUOPI;
				step1 = NOP;
				alu_op = ALU_AND;
			end
			8'h2A:	begin
				step0 = ALUOP;
				step1 = NOP;
				alu_op = ALU_ROL;
			end
			8'h2C:	begin
				step0 = AABS;
				step1 = BIT;
			end
			8'h2D:	begin
				step0 = AABS;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h2E:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROL;
			end
			
			
			8'h30:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'h31:	begin
				step0 = AINY;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h35:	begin
				step0 = AZPX;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h36:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROL;
			end
			8'h38:	begin
				step0 = SEC;
				step1 = NOP;
			end
			8'h39:	begin
				step0 = AABY;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h3D:	begin
				step0 = AABX;
				step1 = ALUOP;
				alu_op = ALU_AND;
			end
			8'h3E:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROL;
			end
			
			
			8'h40:	begin
				step0 = RTI;
				step1 = NOP;
			end
			8'h41:	begin
				step0 = AINX;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h45:	begin
				step0 = AZEP;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h46:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_LSR;
			end
			8'h48:	begin
				step0 = PHA;
				step1 = NOP;
			end
			8'h49:	begin
				step0 = ALUOPI;
				step1 = NOP;
				alu_op = ALU_EOR;
			end
			8'h4A:	begin
				step0 = ALUOP;
				step1 = NOP;
				alu_op = ALU_LSR;
			end
			8'h4C:	begin
				step0 = JMPA;
				step1 = NOP;
			end
			8'h4D:	begin
				step0 = AABS;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h4E:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_LSR;
			end
			
			
			8'h50:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'h51:	begin
				step0 = AINY;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h55:	begin
				step0 = AZPX;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h56:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_LSR;
			end
			8'h58:	begin
				step0 = CLI;
				step1 = NOP;
			end
			8'h59:	begin
				step0 = AABY;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h5D:	begin
				step0 = AABX;
				step1 = ALUOP;
				alu_op = ALU_EOR;
			end
			8'h5E:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_LSR;
			end
			
			
			8'h60:	begin
				step0 = RTS;
				step1 = NOP;
			end
			8'h61:	begin
				step0 = AINX;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h65:	begin
				step0 = AZEP;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h66:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				alu_op = ALU_ROR;
			end
			8'h68:	begin
				step0 = PLA;
				step1 = NOP;
			end
			8'h69:	begin
				step0 = ALUOPI;
				step1 = NOP;
				alu_op = ALU_ADC;
			end
			8'h6A:	begin
				step0 = ALUOP;
				step1 = NOP;
				alu_op = ALU_ROR;
			end
			8'h6C:	begin
				step0 = JMPI;
				step1 = NOP;
			end
			8'h6D:	begin
				step0 = AABS;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h6E:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROR;
			end
			
			8'h70:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'h71:	begin
				step0 = AINY;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h75:	begin
				step0 = AZPX;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h76:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROR;
			end
			8'h78:	begin
				step0 = SEI;
				step1 = NOP;
			end
			8'h79:	begin
				step0 = AABY;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h7D:	begin
				step0 = AABX;
				step1 = ALUOP;
				alu_op = ALU_ADC;
			end
			8'h7E:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_ROR;
			end
			
			
			8'h81:	begin
				step0 = AINX;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h84:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGY;
				alu_op = ALU_LOAD;
			end
			8'h85:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h86:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGX;
				alu_op = ALU_LOAD;
			end
			8'h88:	begin
				step0 = ALUOP;
				step1 = NOP;
				register = REGY;
				alu_op = ALU_DEC;
			end
			8'h8A:	begin
				step0 = TXA;
				step1 = NOP;
			end
			8'h8C:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGY;
				alu_op = ALU_LOAD;
			end
			8'h8D:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h8E:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGX;
				alu_op = ALU_LOAD;
			end
			
			
			8'h90:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'h91:	begin
				step0 = AINY;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h94:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGY;
				alu_op = ALU_LOAD;
			end
			8'h95:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h96:	begin
				step0 = AZPY;
				step1 = ALUMEM;
				register = REGX;
				alu_op = ALU_LOAD;
			end
			8'h98:	begin
				step0 = TYA;
				step1 = NOP;
			end
			8'h99:	begin
				step0 = AABY;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			8'h9A:	begin
				step0 = TXS;
				step1 = NOP;
			end
			8'h9D:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGACC;
				alu_op = ALU_LOAD;
			end
			
			
			8'hA0:	begin
				step0 = ALULOADI;
				step1 = NOP;
				register = REGY;
				alu_op = ALU_LD;
			end
			8'hA1:	begin
				step0 = AINX;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hA2:	begin
				step0 = ALULOADI;
				step1 = NOP;
				register = REGX;
				alu_op = ALU_LD;
			end
			8'hA4:	begin
				step0 = AZEP;
				step1 = ALULOAD;
				register = REGY;
				alu_op = ALU_LD;
			end
			8'hA5:	begin
				step0 = AZEP;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hA6:	begin
				step0 = AZEP;
				step1 = ALULOAD;
				register = REGX;
				alu_op = ALU_LD;
			end
			8'hA8:	begin
				step0 = TAY;
				step1 = NOP;
			end
			8'hA9:	begin
				step0 = ALULOADI;
				step1 = NOP;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hAA:	begin
				step0 = TAX;
				step1 = NOP;
			end
			8'hAC:	begin
				step0 = AABS;
				step1 = ALULOAD;
				register = REGY;
				alu_op = ALU_LD;
			end
			8'hAD:	begin
				step0 = AABS;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hAE:	begin
				step0 = AABS;
				step1 = ALULOAD;
				register = REGX;
				alu_op = ALU_LD;
			end
			
			
			8'hB0:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'hB1:	begin
				step0 = AINY;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hB4:	begin
				step0 = AZPX;
				step1 = ALULOAD;
				register = REGY;
				alu_op = ALU_LD;
			end
			8'hB5:	begin
				step0 = AZPX;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hB6:	begin
				step0 = AZPY;
				step1 = ALULOAD;
				register = REGX;
				alu_op = ALU_LD;
			end
			8'hB8:	begin
				step0 = CLV;
				step1 = NOP;
			end
			8'hB9:	begin
				step0 = AABY;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hBA:	begin
				step0 = TSX;
				step1 = NOP;
			end
			8'hBC:	begin
				step0 = AABX;
				step1 = ALULOAD;
				register = REGY;
				alu_op = ALU_LD;
			end
			8'hBD:	begin
				step0 = AABX;
				step1 = ALULOAD;
				register = REGACC;
				alu_op = ALU_LD;
			end
			8'hBE:	begin
				step0 = AABY;
				step1 = ALULOAD;
				register = REGX;
				alu_op = ALU_LD;
			end
			
			
			8'hC0:	begin
				step0 = CMPI;
				step1 = NOP;
				register = REGY;
			end
			8'hC1:	begin
				step0 = AINX;
				step1 = CMP;
				register = REGACC;
			end
			8'hC4:	begin
				step0 = AZEP;
				step1 = CMP;
				register = REGY;
			end
			8'hC5:	begin
				step0 = AZEP;
				step1 = CMP;
				register = REGACC;
			end
			8'hC6:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_DEC;
			end
			8'hC8:	begin
				step0 = ALUOP;
				step1 = NOP;
				register = REGY;
				alu_op = ALU_INC;
			end
			8'hC9:	begin
				step0 = CMPI;
				step1 = NOP;
				register = REGACC;
			end
			8'hCA:	begin
				step0 = ALUOP;
				step1 = NOP;
				register = REGX;
				alu_op = ALU_DEC;
			end
			8'hCC:	begin
				step0 = AABS;
				step1 = CMP;
				register = REGY;
			end
			8'hCD:	begin
				step0 = AABS;
				step1 = CMP;
				register = REGACC;
			end
			8'hCE:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_DEC;
			end
			
			
			8'hD0:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'hD1:	begin
				step0 = AINY;
				step1 = CMP;
				register = REGACC;
			end
			8'hD5:	begin
				step0 = AZPX;
				step1 = CMP;
				register = REGACC;
			end
			8'hD6:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_DEC;
			end
			8'hD8:	begin
				step0 = CLD;
				step1 = NOP;
			end
			8'hD9:	begin
				step0 = AABY;
				step1 = CMP;
				register = REGACC;
			end
			8'hDD:	begin
				step0 = AABX;
				step1 = CMP;
				register = REGACC;
			end
			8'hDE:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_DEC;
			end
			
			
			8'hE0:	begin
				step0 = CMPI;
				step1 = NOP;
				register = REGX;
			end
			8'hE1:	begin
				step0 = AINX;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hE4:	begin
				step0 = AZEP;
				step1 = CMP;
				register = REGX;
			end
			8'hE5:	begin
				step0 = AZEP;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hE6:	begin
				step0 = AZEP;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_INC;
			end
			8'hE8:	begin
				step0 = ALUOP;
				step1 = NOP;
				register = REGX;
				alu_op = ALU_INC;
			end
			8'hE9:	begin
				step0 = ALUOPI;
				step1 = NOP;
				alu_op = ALU_SBC;
			end
			8'hEA:	begin
				step0 = NOP;
				step1 = NOP;
			end
			8'hEC:	begin
				step0 = AABS;
				step1 = CMP;
				register = REGX;
			end
			8'hED:	begin
				step0 = AABS;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hEE:	begin
				step0 = AABS;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_INC;
			end
			
			
			8'hF0:	begin
				step0 = WBR;
				if (branch)
					step1 = BRA;
				else
					step1 = NBR;
			end
			8'hF1:	begin
				step0 = AINY;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hF5:	begin
				step0 = AZPX;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hF6:	begin
				step0 = AZPX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_INC;
			end
			8'hF8:	begin
				step0 = SED;
				step1 = NOP;
			end
			8'hF9:	begin
				step0 = AABY;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hFD:	begin
				step0 = AABX;
				step1 = ALUOP;
				alu_op = ALU_SBC;
			end
			8'hFE:	begin
				step0 = AABX;
				step1 = ALUMEM;
				register = REGDIN;
				alu_op = ALU_INC;
			end
			
			default:	begin
				step0 = NOP;
				step1 = NOP;
			end
			
		endcase
	end	
	
	//interrupts/opcode fetch
	always @(*) begin
		if (~nmi_n)
			int_i = INMI;
		else if (~irq_n & irqen)
			int_i = IIRQ;
		else
			int_i = IOPC;
	end
	
endmodule