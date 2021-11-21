//////////////////////////////////////////////////////////////
// mc_defs.sv - Global definitions for memory controller
// Author:	Roy Kravitz (roy.kravitz@pdx.edu) 
// Date:	09-Nov-2021
//
// Description:
// ------------
// Contains the global typedefs, const, enum, structs, etc. for the memory
// controller assignment 
////////////////////////////////////////////////////////////////
package mc_defs;

parameter	BUSWIDTH = 16;
parameter   ADDRWIDTH = 16;
parameter   PAGEBITS = 4;                   // page bits in the page address
parameter   MEMADDRBITS = 12;               // memory array address bits
parameter	MEMSIZE = 2**MEMADDRBITS;       // memory size based on memory address
parameter	DATAPAYLOADSIZE = 4;

// page number for the memory controller
parameter [PAGEBITS-1:0] MEMPAGE1 = 4'h2;
parameter [PAGEBITS-1:0] MEMPAGE2 = 4'h3;

endpackage: mc_defs