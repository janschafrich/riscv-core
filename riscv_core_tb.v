
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
  	reg clk_tb; 
	reg reset_tb;    // 
  	wire [31:0] pc_next_tb;

/**********************************************************************
** Component instances
**********************************************************************/
// instantiate the device under test
program_counter DUT (     // Device under Test
        // Inputs
	.clk(clk_tb),
	.reset(reset_tb),
       
        // Outputs
	.pc_next(pc_next_tb)
        );
	
	always #5 clk_tb = ~clk_tb;

	initial begin
		clk_tb <= 0; 
		reset_tb <= 0;

		#20 reset_tb <= 1;
		#100 reset_tb <= 0;
		#40 reset_tb <= 1;

		#40 $finish;
	end
 
endmodule // riscv_core_tb