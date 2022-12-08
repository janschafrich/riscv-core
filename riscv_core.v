
/* RISC-V CPU Core

RISC-V core based on the design used in edX course by Steve Hoover "Building a RISC-V CPU Core".

core features:
RV32I
pipelined stages: fetch, decode/alu

*/
`timescale 1 ns / 1 ps

module program_counter(
	input clk,
	input reset,
	input taken_br, is_jalr,
	input [31:0]tgt_addr,
	output reg [31:0]pc
	);
	
	reg [31:0]pc_next;		// internal signal

	initial begin
		pc <= 32'bz;
	end
	
	always @(posedge clk)  	begin
		if (!reset) begin
			pc <= 0;			
			pc_next <= 4;
		end
		if(taken_br || is_jalr)
			pc_next <= tgt_addr;
		else
			pc = pc_next;			// use blocking assignments for sequential execution
			pc_next = pc_next + 4;	// 32 bit wide instructions begin every 4 adresses
	end
endmodule

// read only instruction memory
module instruction_memory(
	input wire clk, reset,
	input [31:0] addr,	
	output reg[31:0] instr
	);

	reg [31:0]rom_data;		// signal to store rom until its output via instr

	initial begin
		instr <= 32'b0;
	end

	always @(posedge clk) begin 
		if(!reset)
			instr <= 32'b0;
		else 
			instr <= rom_data;
	end
	always @*
		case(addr)	// lookup table - instructions from Steven Hoover RISC-V tutorial https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core.git
			//                                            imm		    	     rs1   funct3   rd      opcode
			32'h0:	rom_data = 32'b0000_0001_0101_00000_000_00001_0010011;		// (I) ADDI x1, x0, 10101
			32'h4:	rom_data = 32'b0000_0000_0111_00000_000_00010_0010011;		// (I) ADDI x2, x0, 111
			32'h8:	rom_data = 32'b1111_1111_1100_00000_000_00011_0010011;		// (I) ADDI x3, x0, 111111111100
			32'hc:	rom_data = 32'b0000_0101_1100_00001_111_00101_0010011;		// (I) ANDI x5, x1, 1011100
			32'h10:	rom_data = 32'b0000_0001_0101_00101_100_00101_0010011;		// (I) XORI x5, x5, 10101
			32'h14:	rom_data = 32'b0000_0101_1100_00001_110_00110_0010011;		// (I) ORI x6, x1, 1011100
			32'h18:	rom_data = 32'b0000_0101_1100_00110_100_00110_0010011;		// (I) XORI x6, x6, 1011100
			32'h1c:	rom_data = 32'b0000_0000_0111_00001_000_00111_0010011;		// (I) ADDI x7, x1, 111
			32'h20:	rom_data = 32'b0000_0001_1101_00111_100_00111_0010011;		// (I) XORI x7, x7, 11101
			32'h24:	rom_data = 32'b0000_0000_0110_00001_001_01000_0010011;		// (I) SLLI x8, x1, 110
			32'h28:	rom_data = 32'b0101_0100_0001_01000_100_01000_0010011;		// (I) XORI x8, x8, 10101000001
			32'h2c:	rom_data = 32'b0000_0000_0010_00001_101_01001_0010011;		// (I) SRLI x9, x1, 10
			32'h30:	rom_data = 32'b0000_0000_0100_01001_100_01001_0010011;		// (I) XORI x9, x9, 100
			32'h34:	rom_data = 32'b0000_0000_0010_0000_1111_0101_0011_0011;		// Cycle 13 (R) AND r10, x1, x2
			32'h38:	rom_data = 32'b0000_0000_0000_0000_0000_1001_1011_0111;		// Cycle 31 (U) LUI x19, 0
			32'h3c:	rom_data = 32'b0000_0000_0100_0000_0000_1100_1110_1111;		// Cycle 44 (J) JAL x25, 10
			32'h40:	rom_data = 32'b0000_0000_0001_0001_0010_0000_1010_0011;		// Cycle 51 (S) SW x2, x1, 1
		endcase
endmodule


// extract information from instruction
module instruction_decode(
	input wire clk, reset,
	input [31:0]instr, pc,
	output reg [6:0]opcode,		
	output reg[2:0]funct3,
	output reg[31:0]imm, 		// immediate value (= operand that is decoded inside the instruction)
	output reg [10:0]dec_bits,	// instruction identification
	output reg[31:0]rslt_value,
	output reg taken_br,  is_jalr
	);

	// signals
	// signals for decode
	reg is_r_instr, is_i_instr, is_s_instr, is_b_instr, is_u_instr, is_j_instr;
	// signals for the register
	reg [31:0]register_file[31:0];					// 2D array (Matrix): word size, register count
	reg rd_valid, funct3_valid, rs1_valid, rs2_valid, imm_valid;
	reg [4:0] rs1, rs2, rd;							// destination register, source register 1, source register 2
	reg [31:0] src1_value, src2_value;
	// signals for the ALU
	reg is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu, is_jal; 
	reg is_addi, is_add, is_sub;
	reg is_lui, is_auipc;
	reg is_xor, is_xori, is_or, is_ori, is_andi, is_and;
	reg is_slt, is_slti, is_sltu, is_sltiu, is_slli, is_srli, is_sra, is_srai, is_sll, is_srl;
	

	initial begin
		is_r_instr <= 0;
		is_i_instr <= 0;
		is_s_instr <= 0;
		is_b_instr <= 0;
		is_u_instr <= 0;
		is_j_instr <= 0;
		register_file[0] <= 32'b0;		// register 0 is hardware b0	RISC-V spec p. 9
		src1_value <= 32'b0;
		src2_value <= 32'b0;
		rslt_value <= 32'b0;
		taken_br <= 1'b0;
	end

	always @(posedge clk) begin	// RISC-V spec v2.2 p. 104
		if(!reset) begin
			is_r_instr <= 0; is_i_instr <= 0; is_s_instr <= 0; is_b_instr <= 0; is_u_instr <= 0; is_j_instr <= 0;
			opcode <= 7'b0; rd <= 5'b0; funct3 <= 3'b0; rs1 <= 5'b0; rs2 <= 5'b0; imm <= 32'b0; 
			rd_valid <= 0; funct3_valid <= 0; rs1_valid <= 0; rs2_valid <= 0; imm_valid <= 0;
			dec_bits <= 11'b0;
			is_addi <= 0; is_add <= 0; 
			is_beq <= 0; is_bne <= 0; is_blt <= 0; is_bge <= 0; is_bltu <= 0; is_bgeu <= 0;	
			src1_value <= 32'b0; src2_value <= 32'b0; register_file[0] <= 32'b0;
			rslt_value <= 32'b0;	taken_br <= 1'b0;
		end
		else begin
		
			// determine instruction type
			is_r_instr <= instr[6:2] == 5'b01011 || instr[6:2] == 5'b01100 || instr[6:2] == 5'b01110 || instr[6:2] == 5'b10100;
			is_i_instr <= instr[6:2] == 5'b00000 || instr[6:2] == 5'b00001 || instr[6:2] == 5'b00100 || instr[6:2] == 5'b00110 || instr[6:2] == 5'b11001;
			is_s_instr <= instr[6:2] == 5'b01000 || instr[6:2] == 5'b01001;
			is_b_instr <= instr[6:2] == 5'b11000;
			is_u_instr <= instr[6:2] == 5'b00101 || instr[6:2] == 5'b01101;
			is_j_instr <= instr[6:2] == 5'b11011;
	
		end
	end
		

	always @(instr or is_r_instr or is_i_instr or is_s_instr or is_b_instr or is_u_instr or is_j_instr) begin
		// determine whether field is present in current instruction
		rd_valid 		<= is_r_instr == 1 || is_i_instr == 1 || is_u_instr == 1 || is_j_instr == 1;
		funct3_valid 	<= is_r_instr == 1 || is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		rs1_valid 	<= is_r_instr == 1 || is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		rs2_valid 	<= is_r_instr == 1 || is_s_instr == 1 || is_b_instr == 1;
		imm_valid	<= is_i_instr == 1 || is_s_instr == 1 || is_b_instr == 1 || is_u_instr == 1 || is_j_instr == 1;

		//construct immediate value out of instruction fields - RISC-V spec v2.2 p. 12 https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf
		imm <= 	is_i_instr ? { {21{instr[31]}}, {instr[30:20]} } :
				is_s_instr ? { {21{instr[31]}}, {instr[30:25]}, {instr[11:8]}, {instr[7]} } :
				is_b_instr ? { {20{instr[31]}}, {instr[7]}, {instr[30:25]}, {instr[11:8]}, {1'b0} } :	// last bit zero = only even target addresses possible
				is_u_instr ? { {instr[31]}, {instr[30:20]}, {instr[19:12]}, {12'b0} } :
				is_j_instr ? { {12{instr[31]}}, {instr[19:12]}, {instr[20]}, {instr[30:25]}, {instr[24:21]}, {1'b0} } :
				32'b0;		// default
	end									

	always @(instr) begin
		//instr or rd_valid or funct3_valid or rs1_valid or rs2_valid
		//determine instruction field values
		opcode 	<= instr[6:0];
		#0.1		// somehow needed to extract the values
		rd 		<= rd_valid ? 	instr[11:7] : 5'b0;		// loaded for S-type instructions as well, but not used
		funct3 	<= funct3_valid ? 	instr[14:12] : 3'b0;
		rs1 		<= rs1_valid ?	instr[19:15] : 5'b0;
		rs2 		<= rs2_valid ? 	instr[24:20]: 5'b0;
	end

	always @(instr or funct3 or opcode) begin
		dec_bits[10:0] <= {instr[30], funct3, opcode};		// RISC-V RV32I Base instruction set spec V2.2 p. 104
		end

	always @(dec_bits) begin
		is_beq 	<= dec_bits[9:0] 		== 10'b_000_1100011;		//branch equal
		is_bne 	<= dec_bits[9:0] 		== 10'b_001_1100011;		//branch not equal
  		is_blt 	<= dec_bits[9:0] 		== 10'b_100_1100011;		//branch less than
  		is_bge 	<= dec_bits[9:0] 		== 10'b_101_1100011;		//branch greater or equal
  		is_bltu 	<= dec_bits[9:0] 		== 10'b_110_1100011;		//branch less than unsigned
  		is_bgeu 	<= dec_bits[9:0] 		== 10'b_111_1100011;		//branch greater than unsigned			
  		is_add 	<= dec_bits[10:0]		== 11'b0_000_0110011;		//add	
		is_lui 	<= dec_bits[6:0]		== 11'b_0110111; 			// load upper immediate
  		is_auipc 	<= dec_bits[6:0]		== 11'b_0010111; 			// add upper immediate to pc
   		is_jal 	<= dec_bits[6:0] 		== 11'b_1101111; 			// jump and link (offset as immediate)
   		is_jalr 	<= dec_bits[6:0]		== 11'b_1100111; 			// jump and link register (offset to be calculated)

   //$is_load = $dec_bits ==? 11'bx_xxx_000011; // dont distinguish between indiviual load instructions
   		is_addi 	<= dec_bits[9:0]		== 11'b_000_0010011; 		// add immediate
   		is_slti 	<= dec_bits[9:0]		== 11'b_010_0010011; 		// set less than immediate
   		is_sltiu 	<= dec_bits[9:0]		== 11'b_011_0010011; 		// set less than immediate unsigned

		is_xori 	<= dec_bits[9:0] 		== 11'b_100_0010011; // bitwise xor immediate
		is_ori 	<= dec_bits[9:0]		== 11'b_110_0010011; // bitwise or immediate
   		is_andi 	<= dec_bits[9:0]		== 11'b_111_0010011; //bitwise and immediate
   		is_slli 	<= dec_bits[10:0]		== 11'b0_001_0010011; // shift left logical immediate
		is_srli 	<= dec_bits[10:0]		== 11'b0_101_0010011; // shift right logical immediate
   		is_srai 	<= dec_bits[10:0]		== 11'b_1_101_0010011; // shift right arithmetic immediate
  
  		// new
   		is_sub 	<= dec_bits[10:0]		== 11'b1_000_0110011;
   		is_sll 	<= dec_bits[10:0]		== 11'b0_001_0110011; // shift left logical
   		is_slt 	<= dec_bits[10:0]		== 11'b0_010_0110011; // set less than
   		is_sltu 	<= dec_bits[10:0]		== 11'b0_011_0110011; // set less than unsigned
   		is_xor 	<= dec_bits[10:0]		== 11'b0_100_0110011; // exclusive or
   		is_srl 	<= dec_bits[10:0]		== 11'b0_101_0110011; // shift right logical
   		is_sra 	<= dec_bits[10:0]		== 11'b1_101_0110011; // shift right arithmetic
   		is_or 	<= dec_bits[10:0]		== 11'b0_110_0110011; 
   		is_and 	<= dec_bits[10:0] 	== 11'b0_111_0110011; 
	end
	//register access
	always @(rs1 or rs2 or rslt_value) begin //rs1_valid or rs2_valid or rd_valid or rs1 or rs2 or rd or rslt_value
		src1_value 		<= rs1_valid	? register_file[rs1] 	: 32'b0;
		src2_value 		<= rs2_valid	? register_file[rs2] 	: 32'b0;
		register_file[rd] 	<= ( (rd != 5'b0) && rd_valid)	? 	rslt_value 	: 32'b0;
	end

	// branch and jump
	always @(*) begin		
		taken_br	<= 	is_beq 	? (src1_value == src2_value) :				// RISC-V spec p.17
					is_bne	? (src1_value != src2_value) :
					is_blt	? ((src1_value < src2_value) ^ (src1_value[31] != src2_value[31])) :	// signed!  src1 < src2   XOR different sign  ;  consider evaluation of: d-8 (=b1000) < d7 (b0111)? 
					is_bge	? ((src1_value >= src2_value) ^ (src1_value[31] != src2_value[31])) :	// signed
					is_bltu	? (src1_value < src2_value) :
					is_bgeu	? (src1_value >= src2_value) :
					is_jal	? 1'b1 :									// branch target address is computed the same way as for conditional branches, RISC-V spec p. 15
					1'b0;
	end
	
	// arithmetic and logic
	always @(*) begin
		rslt_value[31:0] <= 	is_addi 	? src1_value + imm :					// RISC-V spec p.15
					is_add  	? src1_value + src2_value :
				is_sub	? src1_value - src2_value :
				taken_br	? pc + imm :									// RISC-V spec p.15 / p.17
				is_jalr	? src1_value + imm :							// RISC-V spec p. 16
				is_or	? src1_value | src2_value :
				is_ori	? src1_value | imm :
				is_xor	? src1_value ^ src2_value :
				is_xori 	? src1_value ^ imm :
				is_and 	? src1_value & src2_value :
				is_andi	? src1_value & imm :
				is_slt	? (src1_value[31] ^ src2_value[31]) ? 					// RISC-V spec p. 13 "set rd 1 if src1_value is less than immediate"
							{31'b0, src1_value < src2_value} : 
							{31'b0, (src1_value - src2_value < 0)} :
				is_slti	? (src1_value[31] ^ imm[31]) ? 					// RISC-V spec p. 13 "set rd 1 if src1_value is less than immediate"
							{31'b0, src1_value < imm} : 
							{31'b0, (src1_value - imm < 0)} :
				is_sltu	? {31'b0, (src1_value - src2_value < 0)} :
				is_sltiu	? {31'b0, (src1_value - imm < 0)} :	
				is_sll	? src1_value << src2_value[4:0] :
				is_slli	? src1_value << imm[4:0] :
				is_srl	? src1_value >> src2_value[4:0] :
				is_srli	? src1_value >> imm[4:0] :
				is_sra	? {{ 32{src1_value[31]} } , src1_value} >> src2_value[4:0]: 
				is_srai	? {{ 32{src1_value[31]} } , src1_value} >> imm[4:0]: 					// concat to 64 bit, extend sign into the upper half, than shift
			
 				is_lui	? {imm[31:12], 12'b0} :						// RISC-V spec p.14
				is_auipc 	?  {imm[31:12], 12'b0} + pc :					// RISC-V spec p.14
				32'b0; // default
	end
endmodule
