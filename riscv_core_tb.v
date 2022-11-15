
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
	wire [4:0]rd_tb;			// destination register
	wire [2:0]funct3_tb;
	wire[4:0]rs1_tb;		// source register 1
	wire [4:0]rs2_tb;			// source register 1
	wire [31:0]imm_tb;		// immediate value (= operand that is decoded inside the instruction)
	wire rd_valid_tb, funct3_valid_tb, rs1_valid_tb, rs2_valid_tb, imm_valid_tb;
	wire [10:0]dec_bits_tb;
	wire is_beq_tb, is_bne_tb, is_blt_tb, is_bge_tb, is_bltu_tb, is_bgeu_tb;
	wire is_addi_tb, is_add_tb;

	// register bank
	wire [31:0]value_write_tb;
	

/**********************************************************************
** Component instances
**********************************************************************/
// instantiate the device under test
program_counter pc_dut (     // Device under Test
        // Inputs
	.clk(clk_tb),
	.reset(reset_tb),
        // Outputs
	.pc(pc_tb)
        );

instruction_memory irom_dut(
	// Inputs
	.clk(clk_tb),
	.addr(pc_tb),
	// Outputs
	.instr(instr_tb)
	);

instruction_decode dec_dut(
	//Inputs
	.clk(clk_tb),
	.instr(instr_tb),
	// Outputs
	.is_r_instr(is_r_instr_tb), .is_i_instr(is_i_instr_tb), .is_s_instr(is_s_instr_tb), .is_b_instr(is_b_instr_tb), .is_u_instr(is_u_instr_tb), .is_j_instr(is_j_instr_tb),
	.opcode(opcode_tb), .rd(rd_tb), .funct3(funct3_tb), .rs1(rs1_tb), .rs2(rs2_tb), .imm(imm_tb),
	.rd_valid(rd_valid_tb), .funct3_valid(funct3_valid_tb), .rs1_valid(rs1_valid_tb), .rs2_valid(rs2_valid_tb), .imm_valid(imm_valid_tb),
	.dec_bits(dec_bits_tb),
	.is_beq(is_beq_tb), .is_bne(is_bne_tb), .is_blt(is_blt_tb), .is_bge(is_bge_tb), .is_bltu(is_bltu_tb), .is_bgeu(is_bgeu_tb),
	.is_addi(is_addi_tb), .is_add(is_add_tb)
	);

arithmetic_logic_unit alu_dut(
	// Inputs
	.clk(clk_tb)
	);

register_bank rb_dut(
	//Inputs
	.clk(clk_tb),
	.wren(wren_tb),		// provided by decode
	.rden(rden_tb),
	.rx(rx_tb),
	.write_value(write_value_tb)
	);
	
	always #5 clk_tb = ~clk_tb;

	initial begin
		clk_tb <= 1; 
		reset_tb <= 1;

		#10 reset_tb <= 0;
		#10 reset_tb <= 1;

	end
 
endmodule // riscv_core_tb
