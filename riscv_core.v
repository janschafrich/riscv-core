
/* RISC-V CPU Core

RISC-V core based on the design used in edX course by Steve Hoover "Building a RISC-V CPU Core".

core features:
RV32I

*/
`timescale 1 ns / 1 ps

module program_counter(
	input clk,
	input reset,
	output reg [31:0]pc
	);
	
	reg [31:0]pc_next;		// internal signal

	initial begin
		pc <= 32'b0;
	end
	
	always @(posedge clk)  	begin
		if (!reset) begin
			pc <= 0;			
			pc_next <= 0;
		end
		else
			pc = pc_next;			// use blocking assignments for sequential execution
			pc_next = pc_next + 4;	// 32 bit wide instructions begin every 4 adresses
	end
endmodule

// read only instruction memory
module instruction_memory(
	input wire clk,
	input [31:0] addr,	
	output reg[31:0] instr
	);

	reg [31:0]rom_data;		// signal to store rom until its output via instr

	always @(posedge clk) instr <= rom_data;
	
	always @*
		case(addr)	// lookup table - instructions from Steven Hoover RISC-V tutorial https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core.git
			32'h0:	rom_data = 32'b0000_0001_0101_0000_0000_0000_1001_0011;		// (I) ADDI x1, x0, 10101
			32'h4:	rom_data = 32'b0000_0000_0111_0000_0000_0000_0001_0011;		// (I) ADDI x2, x0, 111
			32'h8:	rom_data = 32'b1111_1111_1100_0000_0000_0001_1001_0011;		// (I) ADDI x3, x0, 111111111100
			32'hc:	rom_data = 32'b0000_0101_1100_0000_1111_0010_1001_0011;		// (I) ANDI x5, x1, 1011100
			32'h10:	rom_data = 32'b0000_0001_0101_0010_1100_0010_1001_0011;		// (I) XORI x6, x6, 10101
			32'h14:	rom_data = 32'b0000_0000_0010_0000_1111_0101_0011_0011;		// Cycle 13 (R) AND r10, x1, x2
			32'h18:	rom_data = 32'b0000_0000_0000_0000_0000_1001_1011_0111;		// Cycle 31 (U) LUI x19, 0
			32'h1c:	rom_data = 32'b0000_0000_0100_0000_0000_1100_1110_1111;		// Cycle 44 (J) JAL x25, 10
			32'h20:	rom_data = 32'b0000_0000_0001_0001_0010_0000_1010_0011;		// Cycle 51 (S) SW x2, x1, 1
		endcase
endmodule


// extract information from instruction
module instruction_decode(
	input wire clk,
	input [31:0]instr,
	output reg is_r_instr, is_i_instr, is_s_instr, is_b_instr, is_u_instr, is_j_instr,
	output reg [6:0]opcode,
	output reg[4:0]rd,			// destination register
	output reg[2:0]funct3,
	output reg[4:0]rs1,		// source register 1
	output reg[4:0]rs2,			// source register 1
	output reg[31:0]imm, src1_value, src2_value, rd_value,		// immediate value (= operand that is decoded inside the instruction)
	output reg rd_valid, funct3_valid, rs1_valid, rs2_valid, imm_valid,
	output reg [10:0]dec_bits,	// instruction identification
	output reg is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu, is_addi, is_add
	);

	// internal signals
	reg [31:0]register_file[31:0];		// 2D array (Matrix): word size, register count

	initial begin
		is_r_instr <= 0;
		is_i_instr <= 0;
		is_s_instr <= 0;
		is_b_instr <= 0;
		is_u_instr <= 0;
		is_j_instr <= 0;
		rd_value <= 0;
	end

	always @(posedge clk) begin	// RISC-V spec v2.2 p. 104
		// determine instruction type
		is_r_instr <= instr[6:2] == 5'b01011 || instr[6:2] == 5'b01100 || instr[6:2] == 5'b01110 || instr[6:2] == 5'b10100;
		is_i_instr <= instr[6:2] == 5'b00000 || instr[6:2] == 5'b00001 || instr[6:2] == 5'b00100 || instr[6:2] == 5'b00110 || instr[6:2] == 5'b11001;
		is_s_instr <= instr[6:2] == 5'b01000 || instr[6:2] == 5'b01001;
		is_b_instr <= instr[6:2] == 5'b11000;
		is_u_instr <= instr[6:2] == 5'b00101 || instr[6:2] == 5'b01101;
		is_j_instr <= instr[6:2] == 5'b11011;

		
		//determine instruction field values
		opcode 	<= instr[6:0];
		rd		<= instr[11:7];		// loaded for S-type instructions as well, but not used
		funct3 	<= instr[14:12];
		rs1		<= instr[19:15];
		rs2 		<= instr[24:20];
	end

	always @(is_r_instr or is_i_instr or is_s_instr or is_b_instr or is_u_instr or is_j_instr) begin
		// determine whether field is present in current instruction
		rd_valid 		<= is_r_instr == 1 || is_i_instr == 1 || is_u_instr == 1 || is_j_instr == 1;
		funct3_valid 	<= is_r_instr == 1 || is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		rs1_valid 		<= is_r_instr == 1 || is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		rs2_valid 		<= is_r_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		imm_valid	<= is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1 || is_u_instr == 1 || is_j_instr == 1;

		//construct immediate value out of instruction fields - RISC-V spec v2.2 p. 12 https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
		if (is_i_instr)
				imm <= { {21{instr[31]}}, {instr[30:20]} };
		else if (is_s_instr)
				imm <= { {21{instr[31]}}, {instr[30:25]}, {instr[11:8]}, {instr[7]} };
		else if (is_b_instr)
				imm <= { {20{instr[31]}}, {instr[7]}, {instr[30:25]}, {instr[11:8]}, {1'b0} };	// last bit zero = only even target addresses possible
		else if (is_u_instr)
				imm <= { {instr[31]}, {instr[30:20]}, {instr[19:12]}, {12'b0} };		
		else if (is_j_instr)
				imm <= { {12{instr[31]}}, {instr[19:12]}, {instr[20]}, {instr[30:25]}, {instr[24:21]}, {1'b0} };
		else
			imm <= 32'b0;	
	end

	always @(instr or funct3 or opcode) begin
		dec_bits[10:0] <= {instr[30], funct3, opcode};		// RISC-V RV32I Base instruction set spec V2.2 p. 104
		end

	always @(dec_bits) begin
		is_beq 	<= dec_bits[9:0] == 10'b_000_1100011;		//branch equal
		is_bne 	<= dec_bits[9:0] == 10'b_001_1100011;		//branch not equal
  		is_blt 	<= dec_bits[9:0] == 10'b_100_1100011;		//branch less than
  		is_bge 	<= dec_bits[9:0] == 10'b_101_1100011;		//branch greater or equal
  		is_bltu 	<= dec_bits[9:0] == 10'b_110_1100011;		//branch less than unsigned
  		is_bgeu 	<= dec_bits[9:0] == 10'b_111_1100011;		//branch greater than unsigned		
  		is_addi 	<= dec_bits[9:0] == 10'b_000_0010011;		//add immediate		
  		is_add 	<= dec_bits 		== 11'b0_000_0110011;		//add	
	end
	
	// register bank access
	always @(rs1_valid or rs2_valid or rd_valid) begin
		if(rs1_valid)
			src1_value <= register_file[rs1];		// load operand from source register 1
		else if(rs2_valid)
			src2_value <= register_file[rs2];
		else if(rd_valid && (rd !=5'b0) )			// never write to register 0
			register_file[rd] <= rd_value;			// store value into the destination register
		else
			register_file[0] <= 32'b0;
	end
endmodule

// ------------------------------------------   // next step: provide src1_value, src2_value, rd_value  // -------------------------------------------- //


/*
module arithmetic_logic_unit(
	input clk,
	input [4:0] dest_value, src1_value, src2_value,
	input [31:0] imm_value,
	input is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu, is_addi, is_add,
	output reg[31:0] result,
	output reg taken_br
);
	always @(posedge clk) begin
	result <= is_addi ? src1_value + imm_value :
			is_add  ? src1_value + src2_value :
			32'b0; // default	

	end
	

endmodule
*/

