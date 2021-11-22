//////////////////////////////////////////////////////////////
// memory_controller.sv - memory controller w/ integrated memory array
//
// NOTE:  YOU DO NOT NEED TO USE THIS CODE OR EVEN LOOK AT IT.  I INCLUDED
// IT TO INTEGRATE THE MEMORY INTO THE CONTROLLER MODULE
//
// Author:	<YOUR NAME>
// Date:	<THE DATE>
//
// Description:
// ------------
// Connects the main bus to a memory array.  In this implementation the
// memory array is integrated into the interface.  From a hardware persective
// where we may build the system this may not be the best implementation.  
// The memory was integrated into the interface for simplication
// 
// NOTE:  I IMPLEMENTED THE MEMORY ARRAY IN THIS MODULE BUT THE REST
// IS UP TO YOU.  
//
// Note:  Original concept by Don T. but the implementation is my own
//////////////////////////////////////////////////////////////////////

// global definitions, parameters, etc.
import mc_defs::*;
	
module memory_controller
#(
	parameter	logic	[3:0] 	PAGE = 4'h2	
)
(
	main_bus_if.secondary 	MBUS		// interface to memory is a slave
);


// variables for memory array
logic [PAGEBITS-1:0]        page;           // page is the upper 4 bits of the address
logic [MEMADDRBITS-1:0]     baseaddr;       // base address for the access
logic [3:0]                 cntr;           // memory reads/writes 4 locations/access
logic [MEMADDRBITS-1:0]	    addr;		    // Memory address
logic [BUSWIDTH-1:0]		DataIn;		    // Data to be written to the memory array
logic [BUSWIDTH-1:0]		DataOut;	    // Data returned from the memory array

logic						clk, resetH;    // system clock and reset
logic						rdEn;		    // Asserted high to perform a memory read
logic						wrEn;		    // Asserted high to perform a memory write
logic					    busdrive;       // Asserted high to drive the AddrData bus

// system clock and reset
assign clk = MBUS.clk;
assign resetH = MBUS.resetH;

//---------------------------------
// Implement the memory array
//---------------------------------

// declare the memory array
logic [BUSWIDTH-1:0]    M[MEMSIZE]; // memory array

// generate DataIn to the memory array from the AddrData bus
assign DataIn = MBUS.AddrData;      // data to the memory array (writes)     
assign MBUS.AddrData = ((page == PAGE) && busdrive) ? DataOut : 'z;  // data from the memory array (reads)
assign addr = baseaddr + cntr;


// read a location from memory.  
always_comb begin
	if (rdEn == 1'b1)
		DataOut = M[addr];
end

// write a location in memory
// We used an always block instead of always_ff because we are using an initial
// block to initialize the memory and we can't drive M[] from two procedural blocks
// using always_ff
always @(posedge MBUS.clk) begin
	if (wrEn == 1'b1) begin
		M[addr] <= DataIn;
	end
end // write a location in memory

initial begin: init_array
    // clear the memory locations
	foreach (M[i]) begin
		M[i] = '0;
	end
end: init_array

//---------------------------------
// Implement the memory controller
//---------------------------------

// ADD YOUR CODE HERE
//fsm 

typedef enum logic[3:0] {A = 4'b0000, RB = 4'b0001, RC = 4'b0010, RD = 4'b0011, RE = 4'b0100, WB = 4'b0101, WC = 4'b0110, WD = 4'b0111, WE = 4'b1000} state_t;
state_t state, next_state; 

//seq block 
always_ff @ (posedge clk)
begin
if (resetH)
	state <= A;			//IDLE state
else 
	state <= next_state;
end

//next_state logic
always_comb
begin
case(state)
	A: 	next_state = MBUS.AddrValid ? (MBUS.rw ? RB : WB) : A;
	RB:	next_state = RC;
	RC:	next_state = RD;
	RD:	next_state = RE;
	RE:	next_state = A;
	//RE:	next_state = MBUS.AddrValid ? (MBUS.rw ? RB : WB) : A;
	WB:	next_state = WC;
	WC:	next_state = WD;
	WD:	next_state = WE;
	WE:	next_state = A;
	//WE:	next_state = MBUS.AddrValid ? (MBUS.rw ? RB : WB) : A;
endcase
end 

//output logic
always_comb
begin
case(state)
	A:	begin
		page = DataIn[15:12];
		baseaddr = DataIn[11:0];
		busdrive = 1'b0;
		rdEn = 1'b0;
		wrEn = 1'b0;
		end
	RB:	begin
		rdEn = 1'b1;
		wrEn = 1'b0;
		cntr = 4'b0000;
		busdrive = 1'b1;
		end
	RC:	begin
		rdEn = 1'b1;
		wrEn = 1'b0;
		cntr = 4'b0001;
		busdrive = 1'b1;
		end
	RD:	begin
		rdEn = 1'b1;
		wrEn = 1'b0;
		cntr = 4'b0010;
		busdrive = 1'b1;
		end
	RE:	begin
		rdEn = 1'b1;
		wrEn = 1'b0;
		cntr = 4'b0011;
		busdrive = 1'b1;
		end
	WB:	begin
		if (page == PAGE) begin
			rdEn = 1'b0;
			wrEn = 1'b1;
			cntr = 4'b0000;
			busdrive = 1'b0;
			end
		end
	WC:	begin
		if (page == PAGE) begin
			rdEn = 1'b0;
			wrEn = 1'b1;
			cntr = 4'b0001;
			busdrive = 1'b0;
			end
		end
	WD:	begin
		if (page == PAGE) begin
			rdEn = 1'b0;
			wrEn = 1'b1;
			cntr = 4'b0010;
			busdrive = 1'b0;
			end
		end
	WE:	begin
		if (page == PAGE) begin
			rdEn = 1'b0;
			wrEn = 1'b1;
			cntr = 4'b0011;
			busdrive = 1'b0;
			end
		end
endcase
end

endmodule: memory_controller
								