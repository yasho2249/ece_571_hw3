//////////////////////////////////////////////////////////////
// main_bus_if.sv - Main Bus interface for HW #3
//
// Author:	Roy Kravitz 
// Date:	09-Nov-2021
//
// Description:
// ------------
// Defines the interface between the processor interface (primary) and
// the memory interface (secondary).  
// 
// Note:  Original concept by Don T. but the implementation is my own
//////////////////////////////////////////////////////////////////////

// global definitions, parameters, etc.
import mc_defs::*;
	
interface main_bus_if
(
	input logic clk,
	input logic resetH
);
	
	// bus signals
	tri		[BUSWIDTH-1: 0]		AddrData;
	logic						AddrValid;
	logic						rw;
	
	modport primary (
		input	clk,
		input	resetH,
		output	AddrValid,
		output	rw,
		inout	AddrData
	);
	
	modport secondary (
		input	clk,
		input	resetH,
		input	AddrValid,
		input	rw,
		inout	AddrData
	);
	
endinterface: main_bus_if