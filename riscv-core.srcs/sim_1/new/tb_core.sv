
/*******************************************************************************
-*                                                                            **
**                               74LS161a Test Bench                          **
**                                                                            **
********************************************************************************
**
** Replace [items in brackets] with your content
** @file AAC2M4P1_tb.v
** @version: 1.0 
** Date of current revision:  @date 2019*08*16  
** Target FPGA: [Intel Altera MAX10] 
** Tools used: Sigasi for editing and synthesis checking 
**             Modeltech ModelSIM 10.4a Student Edition for simulation 
**             
**  Functional Description:  This file contains the Verilog which describes the 
**              test bench for an FPGA implementation of a 16 bit counter.
**              The inputs are a 4 bit vector D, an active low Load_n, ENP and ENT. 
**              
**              Outputs are Q(4-bits) and RCO  
**  Hierarchy:  This test bench uses the AAC2M4P1.vs component found
**              in the Work Library.
**             The YourFPGA component is instantiated. This is the component 
**             under test.  Other devices on the board are modeled as processes 
**             which run concurrently.    The other 
**             devices are listed in the following function sections:
**                [ I.   Clock * generates XX MHz clock 
**                 II.  Reset control
**                 III. Interrupt Control
**                 IV.  Address/Data Bus
**                      etc.         ]
**
**              The FPGA is one module.  The test bench module is one
**              functional section, which compares all the possible
**              input bit vector combinations and checks to see if the
**              result is correct after a 10 ns delay.   

**   TESTS 
**   I. Counter test
**    compare all the possible input bit vector combinations and checks to see 
**    if the result is correct after a 10 ns delay.
**  
**  Designed by:  @author Sanju Prakash Kannioth
**                Univeristy of Colorado
**                sanju.kannioth@colorado.edu 
** 
**      Copyright (c) 2018, 2019 by Tim Scherr
**
** Redistribution, modification or use of this software in source or binary
** forms is permitted as long as the files maintain this copyright. Users are
** permitted to modify this and use it to learn about the field of HDl code.
** Tim Scherr and the University of Colorado are not liable for any misuse
** of this material.
******************************************************************************
** 
*/

`timescale 1 ns / 1 ps   // set timescale to nanoseconds, ps precision
/**********************************************************************
** Libraries
**********************************************************************/
                                                        
/**********************************************************************
** Testbench entity declaration
**********************************************************************/
module riscv_core_tb;  
// no external interface.....THIS IS THE TOP LEVEL


/**********************************************************************
*** constant declarations
**********************************************************************/
//   parameter delay = 10;  //ns  defines the wait period.
//   parameter CLK_PERIOD = 5; //ns defines half clock period

/**********************************************************************                                                                      
** signal declarations (ports of the design under test)
**********************************************************************/
  	//global
	reg clk_tb; 
	reg reset_tb;    

	// program counter 
	wire [31:0] pc_tb;

	// instr rom
	wire [31:0] instr_tb;

	// instr decode
	wire is_r_instr_tb, is_i_instr_tb, is_s_instr_tb, is_b_instr_tb, is_u_instr_tb, is_j_instr_tb;
	wire [6:0]opcode_tb;
	wire [4:0]rd_tb, rs1_tb, rs2_tb;			// destination register, source register 1, source register 2
	wire [2:0]funct3_tb;
	wire [31:0]imm_tb, src1_value_tb, src2_value_tb;		// immediate value (= operand that is decoded inside the instruction)
	wire rd_valid_tb, funct3_valid_tb, rs1_valid_tb, rs2_valid_tb, imm_valid_tb;
	wire [10:0]dec_bits_tb;
	wire is_beq_tb, is_bne_tb, is_blt_tb, is_bge_tb, is_bltu_tb, is_bgeu_tb, is_lui_tb, is_auipc_tb, is_jal_tb, is_jalr_tb;
	wire is_addi_tb, is_add_tb, is_sub_tb;
	wire is_xor_tb, is_xori_tb, is_or_tb, is_ori_tb, is_andi_tb, is_and_tb;
	wire is_slt_tb, is_sltu_tb, is_slti_tb, is_sltiu_tb, is_sll_tb, is_slli_tb, is_srl_tb, is_srli_tb, is_sra_tb, is_srai_tb;
	// register file
	//wire [31:0]register_file_tb[31:0];

	//alu
	wire [31:0]dest_value_tb;
	wire taken_br_tb;
	
	
	

/**********************************************************************
** Component instances
**********************************************************************/
// instantiate the device under test
program_counter pc_dut (     // Device under Test
        // Inputs
	.clk(clk_tb),
	.reset(reset_tb),
	.tgt_addr(dest_value_tb),
	.taken_br(taken_br_tb),
	.is_jalr(is_jalr_tb),
        // Outputs
	.pc(pc_tb)
        );

instruction_memory irom_dut(
	// Inputs
	.clk(clk_tb),
	.reset(reset_tb),
	.addr(pc_tb),
	// Outputs
	.instr(instr_tb)
	);

instruction_decode dec_dut(
	//Inputs
	.clk(clk_tb),
	.reset(reset_tb),
	.instr(instr_tb),
	// Outputs
	.is_r_instr(is_r_instr_tb), .is_i_instr(is_i_instr_tb), .is_s_instr(is_s_instr_tb), .is_b_instr(is_b_instr_tb), .is_u_instr(is_u_instr_tb), .is_j_instr(is_j_instr_tb),
	.opcode(opcode_tb), .rd(rd_tb), .funct3(funct3_tb), .rs1(rs1_tb), .rs2(rs2_tb), .imm(imm_tb),
	.rd_valid(rd_valid_tb), .funct3_valid(funct3_valid_tb), .rs1_valid(rs1_valid_tb), .rs2_valid(rs2_valid_tb), .imm_valid(imm_valid_tb),
	.dec_bits(dec_bits_tb),
	.is_beq(is_beq_tb), .is_bne(is_bne_tb), .is_blt(is_blt_tb), .is_bge(is_bge_tb), .is_bltu(is_bltu_tb), .is_bgeu(is_bgeu_tb),
	.is_addi(is_addi_tb), .is_add(is_add_tb), .is_sub(is_sub_tb),
	.is_lui(is_lui_tb), .is_auipc(is_auipc_tb), .is_jal(is_jal_tb), .is_jalr(is_jalr_tb),
	.is_xor(is_xor_tb), .is_xori(is_xori_tb), .is_or(is_or_tb), .is_ori(is_ori_tb), .is_andi(is_andi_tb), .is_and(is_and_tb),
	.is_slt(is_slt_tb), .is_slti(is_slti_tb), .is_sltu(is_sltu_tb), .is_sltiu(is_sltiu_tb), .is_sll(is_sll_tb), .is_slli(is_slli_tb), .is_srl(is_srl_tb), .is_srli(is_srli_tb), .is_sra(is_sra_tb), .is_srai(is_srai_tb)
	//.register_file(register_file_tb)
	
	);

register_file rf_dut(
	//Inputs
	.clk(clk_tb),
	.reset(reset_tb),
	.rs1(rs1_tb), .rs2(rs2_tb), .rd(rd_tb),
	.rs1_valid(rs1_valid_tb), .rs2_valid(rs2_valid_tb), .rd_valid(rd_valid_tb),
	.dest_value(dest_value_tb),
	// Outputs
	.src1_value(src1_value_tb), .src2_value(src2_value_tb)
	);



arithmetic_logic_unit alu_dut(
	// Inputs
	.clk(clk_tb),
	.reset(reset_tb),
	.src1_value(src1_value_tb), .src2_value(src2_value_tb), .imm(imm_tb), .pc(pc_tb),
	.is_beq(is_beq_tb), .is_bne(is_bne_tb), .is_blt(is_blt_tb), .is_bge(is_bge_tb), .is_bltu(is_bltu_tb), .is_bgeu(is_bgeu_tb),
	.is_addi(is_addi_tb), .is_add(is_add_tb), .is_sub(is_sub_tb),
	.is_lui(is_lui_tb), .is_auipc(is_auipc_tb), .is_jal(is_jal_tb), .is_jalr(is_jalr_tb),
	.is_xor(is_xor_tb), .is_xori(is_xori_tb), .is_or(is_or_tb), .is_ori(is_ori_tb), .is_andi(is_andi_tb), .is_and(is_and_tb),
	.is_slt(is_slt_tb), .is_slti(is_slti_tb), .is_sltu(is_sltu_tb), .is_sltiu(is_sltiu_tb), .is_sll(is_sll_tb), .is_slli(is_slli_tb), .is_srl(is_srl_tb), .is_srli(is_srli_tb), .is_sra(is_sra_tb), .is_srai(is_srai_tb),
	// outputs
	.result(dest_value_tb),
	.taken_br(taken_br_tb)
	);


	always #5 clk_tb = ~clk_tb;

	initial begin
		clk_tb <= 1; 
		reset_tb <= 1;

		#10 reset_tb <= 0;
		#10 reset_tb <= 1;

	end
 
endmodule // riscv_core_tb