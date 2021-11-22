/////////////////////////////////////////////////////////////////////
// tb_mc_top.sv - Top level module for HW #3 memory controller unit test
//
// Author:	Roy Kravitz(roy.kravitz@pdx.edu)
// Date:	10-Nov-2021
//
// Description:
// ------------
// Implements the top level module for my memory controller testbench. 
// You may have to make some modifications for your specific implementation
// 
// Note:  Concept provided by D. Thomas but everything else is my own
//////////////////////////////////////////////////////////////////////
import mc_defs::*;

module tb_mc_top;

// internal variables
bit clk = 0, resetH = 0;


// the main bus interface
main_bus_if MAINBUS(.*);

// memory controller
memory_controller
#(
	.PAGE(4'h2)	
) DUT
(
	.MBUS(MAINBUS)
);

// instantiate the testbench
processor CPU
(
	.MBUS(MAINBUS),
	
    .clk(clk),
    .resetH(resetH)
);


initial begin: clockGenerator
	clk = 0;
	forever #5 clk = ~clk;
end: clockGenerator

// reset the system and start things running
initial begin: setup
	resetH = 1;
	repeat(5) @(posedge clk);
	resetH = 0;
end: setup

endmodule: tb_mc_top
