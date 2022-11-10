
/* RISC-V CPU Core





*/


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
		endcase

endmodule
