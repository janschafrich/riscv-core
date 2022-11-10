
/* RISC-V CPU Core





*/


module program_counter(clk, reset, pc_next);
	input clk;
	input reset;
	output reg [31:0]pc_next;
	
//	reg [31:0]pc;		// internal signal

/*	initial begin
		pc <= 32'b0;
	end
*/	
	always @(posedge clk)  	begin
		if (!reset) 
			pc_next <= 0;
		else
			pc_next <= pc_next + 1;
	end
endmodule
