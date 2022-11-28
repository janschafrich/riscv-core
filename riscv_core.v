
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
	input tgt_addr,
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
			32'h14:	rom_data = 32'b0000_0000_0010_0000_1111_0101_0011_0011;		// Cycle 13 (R) AND r10, x1, x2
			32'h18:	rom_data = 32'b0000_0000_0000_0000_0000_1001_1011_0111;		// Cycle 31 (U) LUI x19, 0
			32'h1c:	rom_data = 32'b0000_0000_0100_0000_0000_1100_1110_1111;		// Cycle 44 (J) JAL x25, 10
			32'h20:	rom_data = 32'b0000_0000_0001_0001_0010_0000_1010_0011;		// Cycle 51 (S) SW x2, x1, 1
		endcase
endmodule


// extract information from instruction
module instruction_decode(
	input wire clk, reset,
	input [31:0]instr,
	output reg is_r_instr, is_i_instr, is_s_instr, is_b_instr, is_u_instr, is_j_instr,
	output reg [6:0]opcode,
	output reg[4:0]rd,	rs1, rs2,		// destination register, source register 1, source register 2
	output reg[2:0]funct3,
	output reg[31:0]imm, //src1_value, src2_value, dest_value,		// immediate value (= operand that is decoded inside the instruction)
	output reg rd_valid, funct3_valid, rs1_valid, rs2_valid, imm_valid,
	output reg [10:0]dec_bits,	// instruction identification
	output reg is_addi, is_add, is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu, is_lui, is_auipc, is_jal, is_jalr,
	output reg is_xori, is_ori, is_andi, is_and,
	output reg is_slti, is_sltiu
	);

	initial begin
		is_r_instr <= 0;
		is_i_instr <= 0;
		is_s_instr <= 0;
		is_b_instr <= 0;
		is_u_instr <= 0;
		is_j_instr <= 0;
		//rd_value <= 0;
	end

	always @(posedge clk) begin	// RISC-V spec v2.2 p. 104
		if(!reset) begin
			is_r_instr <= 0; is_i_instr <= 0; is_s_instr <= 0; is_b_instr <= 0; is_u_instr <= 0; is_j_instr <= 0;
			opcode <= 7'b0; rd <= 5'b0; funct3 <= 3'b0; rs1 <= 5'b0; rs2 <= 5'b0; imm <= 32'b0; 
			rd_valid <= 0; funct3_valid <= 0; rs1_valid <= 0; rs2_valid <= 0; imm_valid <= 0;
			dec_bits <= 11'b0;
			is_addi <= 0; is_add <= 0; 
			is_beq <= 0; is_bne <= 0; is_blt <= 0; is_bge <= 0; is_bltu <= 0; is_bgeu <= 0;	
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
		if (is_i_instr )
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

	always @(*) begin
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

			// instructions are not correctly decoded. 
			//rd, rs1, funct3 are not extracted			
			//dec_bits is not correctly constructed
			

		is_xori 	<= dec_bits[9:0] 		== 11'b_100_0010011; // bitwise xor immediate
		is_ori 	<= dec_bits[9:0]		== 11'b_110_0010011; // bitwise or immediate
   		is_andi 	<= dec_bits[9:0]		== 11'b_111_0010011; //bitwise and immediate
   /*
   $is_slli = $dec_bits == 11'b0_001_0010011; // shift left logical immediate
   $is_srli = $dec_bits == 11'b0_101_0010011; // shift right logical immediate
   $is_srai = $dec_bits == 11'b_1_101_0010011; // shift right arithmetic immediate
   $is_add = $dec_bits == 11'b0_000_0110011;
   $is_sub = $dec_bits == 11'b1_000_0110011;
   $is_sll = $dec_bits == 11'b0_001_0110011; // shift logical left
   $is_slt = $dec_bits == 11'b0_010_0110011; // set less than
   $is_sltu = $dec_bits == 11'b0_011_0110011; // set less than unsigned
   $is_xor = $dec_bits == 11'b0_100_0110011; // exclusive or
   $is_srl = $dec_bits == 11'b0_101_0110011; // shift right logical
   $is_sra = $dec_bits == 11'b1_101_0110011; // shift right arithmetic
   $is_or = $dec_bits == 11'b0_110_0110011; */
   		is_and 	<= dec_bits[10:0] 	== 11'b0_111_0110011; 
	end
endmodule



module register_file(
	input clk, reset,
	input rs1_valid, rs2_valid, rd_valid,
	input [4:0]rs1, rs2, rd,
	input [31:0] dest_value,
	output reg[31:0] src1_value, src2_value
	);

	reg [31:0]register_file[31:0];		// 2D array (Matrix): word size, register count

	initial begin
		register_file[0] <= 32'b0;		// register 0 is hardware b0	
		src1_value <= 32'b0;
		src2_value <= 32'b0;
	end

	always @(posedge clk) begin
		if(!reset) begin
			src1_value <= 32'b0;
			src2_value <= 32'b0;
		end
		else if(rs1_valid)
			src1_value <= register_file[rs1];		// load operand from source register 1
		else if(rs2_valid)
			src2_value <= register_file[rs2];
		else if(rd_valid && (rd != 5'b0) )			// never write to register 0
			register_file[rd] <= dest_value;		// store value into the destination register
		else
			register_file[0] <= 32'b0;
	end
endmodule


module arithmetic_logic_unit(
	input clk, reset,
	input [31:0] src1_value, src2_value,
	input [31:0] imm, pc,
	input is_addi, is_add, 
	input is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu, is_lui, is_auipc, is_jal, is_jalr,
	input is_xori, is_ori, is_andi, is_and,
	input is_slti, is_sltiu,
	output reg[31:0] result,
	output reg taken_br
);
	always @(posedge clk) begin
		if (!reset) begin
			result <= 32'b0;
			taken_br <= 1'b0;
		end 
		else begin
		taken_br	= 	is_beq 	? (src1_value == src2_value) :				// RISC-V spec p.17
					is_bne	? (src1_value != src2_value) :
					is_blt	? ((src1_value < src2_value) ^ (src1_value[31] != src2_value[31])) :		// signed!  src1 < src2   XOR different sign  ;  consider evaluation of: d-8 (=b1000) < d7 (b0111)? 
					is_bge	? ((src1_value >= src2_value) ^ (src1_value[31] != src2_value[31])) :	// signed
					is_bltu	? (src1_value < src2_value) :
					is_bgeu	? (src1_value >= src2_value) :
					is_jal	? 1'b1 :									// branch target address is computed the same way as for conditional branches, RISC-V spec p. 15
					1'b0;
		result = 	is_addi 	? src1_value + imm :
				is_add  	? src1_value + src2_value :
				taken_br	? pc + imm :									// RISC-V spec p.15 / p.17
				is_jalr	? src1_value + imm :							// RISC-V spec p. 16
				is_slti	? (src1_value[31] == imm[31]) ? 			// RISC-V spec p. 13
							{31'b0, src1_value < imm} : 
							{31'b0, src1_value[31]} :
				is_sltiu	? {31'b0, src1_value < imm} :				// 0000000000000000000000 comp
				32'b0; // default
		end
	end
endmodule
