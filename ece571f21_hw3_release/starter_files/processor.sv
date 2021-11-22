//////////////////////////////////////////////////////////////
// processor.sv - Processor simulator for memory controller testbench
//
// NOTE:  YOU DO NOT NEED TO USE THIS CODE OR EVEN LOOK AT IT.  I INCLUDED
// IT TO GIVE YOU AN IDEA OF HOW TO USE TASKS TO PERFORM OPERATIONS.
//
// Author:	Yashodhan Wagle <ywagle@pdx.edu> and Ramaa Potnis <rgp2@pdx.edu>
// Date:	11/20/2021
//
// Description:
// ------------
// Implements a testbench for the memory controller unit.  This is a 
// basic testbench targeted for unit testing. 
//
// The testbench implements CPU read and write tasks which are called in an
// initial block to test some basic operations.  These basic operations
// can be applied to more complex test sequences.
// 
// Note:  Loosely based on code provided by D. Thomas but mostly my own
//
// NOTE: I included my code for the CPU_rdReq() task.  This task retrieves
// the data from the memory controller and compares it to the TBMEM which
// is written for every write transaction.  You do not need to use it or
// even use the same approach I used.
//
////////////////////////////////////////////////////////////////

program processor
(
    main_bus_if.primary MBUS,		// interface from the simulated CPU is a master
    
    input bit clk,                  // clock and reset from the clock generator
    input bit resetH
);

import mc_defs::*;

// make use of the SystemVerilog C programming interface
// https://stackoverflow.com/questions/33394999/how-can-i-know-my-current-path-in-system-verilog
import "DPI-C" function string getenv(input string env_name);

// declare internal variables
bit						busdrive;			// drives data from CPU to 
											// AddrData bus
bit [BUSWIDTH-1:0]      TBMem[MEMSIZE];     // testbench memory array
bit [BUSWIDTH-1:0] 	    ad;					// internal address/data bus

int						total_errors;		// total errors (can only be updated on reads)

///////////////////////////////////////////////////
// CPU Emulator - does reads and writes to array //
// via the main bus and the memory controller    //
///////////////////////////////////////////////////

//---------- CPU read request --------------
//- reads data from memory and stores it in 
//- TBMEM[baseaddr]..TBMEM[baseaddr + 3]
//------------------------------------------

// bus driver for AddrData bus
assign MBUS.AddrData = busdrive ? ad : 'z;

task CPU_rdReq(input bit [3:0] page, bit [11:0] baseaddr);
	logic	[15:0]	dbuffer[4];		// memory data buffer
	int				errCnt;			// error count
	int				i;				// loop index
	bit		[11:0]	tbmemAdr;		// Testbench memory address
	
	// drive the address onto AddrData
	@(posedge clk);  // state A in the timing diagram
	busdrive <= 1;
	ad[15:12] <= page;
	ad[11:0] <= baseaddr;
	
	MBUS.AddrValid <= 1;
	MBUS.rw <= 1;
	errCnt <= 0;
	
	@(posedge clk);	// state B, C, D, and E in the timing diagram
	MBUS.AddrValid <= 0;
	MBUS.rw <= 0;
	busdrive <= 0;
    
    // wait for memory to start driving the AddrData bus w/ the data from memory
    wait($isunknown(MBUS.AddrData) == 0);
	for (i = 0; i < DATAPAYLOADSIZE; i++) begin
		dbuffer[i] <= MBUS.AddrData;
		@(posedge clk);
	end
	
	#1;
	$display($time,, "Memory Read from (base)Address %4h to Address %4h:", baseaddr, (baseaddr + 3));
	for (i = 0; i < DATAPAYLOADSIZE; i++) begin
		$display("\t\t\t%4h:\t\Mem data = %4h\tExpected = %4h", 
				(ad + i), dbuffer[i], TBMem[((baseaddr + i) % MEMSIZE)]);
		if (dbuffer[i] != TBMem[((baseaddr + i) % MEMSIZE)]) begin
			errCnt++;
		end
	end
	if (errCnt != 0) begin
		$display("Memory data does not match...better find out why");
	end
	else begin
		$display("Memory data matches...so far, so good");
	end
	total_errors += errCnt;
	@(posedge clk);
endtask: CPU_rdReq

                                    
//------------- CPU write request --------------------
//- writes data to memory array.  Also stores it in 
//- TBMEM[baseaddr]..TBMEM[baseaddr + 3]
//---------------------------------------------------
task CPU_wrReq(input bit [3:0] page, bit [11:0] baseaddr, bit [15:0] data0, data1, data2, data3);
	
	logic [15:0] dbuffer[4];	//write buffer
	logic errCnt;
	int 	i;
	
	if(page == MEMPAGE1) begin
		TBMem[(baseaddr + 0) % MEMSIZE] = data0;
		TBMem[(baseaddr + 1) % MEMSIZE] = data1;
		TBMem[(baseaddr + 2) % MEMSIZE] = data2;
		TBMem[(baseaddr + 3) % MEMSIZE] = data3;	
		end
	
	$display($time,, "Memory Write to Page: %4h, Address %4h to Address %4h:", page, baseaddr, (baseaddr + 3));
	for (i = 0; i < DATAPAYLOADSIZE; i++) begin
		$display("\t\t\tdata0: %4h, data1: %4h, data2: %4h, data3: %4h", 
				data0, data1, data2, data3)]);
	end

	// mapping the states of the FSM
	@(posedge clk)			//stateA
		busdrive<=1;
		ad[15:12]<=page;                                                               
		ad[11:0]<=baseaddr;
							
		MBUS.AddrValid<=1;					
		MBUS.rw<=0;
		errCnt<=0;
					
							
		@(posedge clk);
		MBUS.AddrValid<=0;					
		ad<=data0;
		@(posedge clk);
		ad<=data1;
		@(posedge clk);
		ad<=data2;
		@(posedge clk);
		ad<=data3;
endtask: CPU_wrReq
	


// set up initial conditions
initial begin: setup
	// initialize memory array
	foreach (TBMem[i]) begin
		TBMem[i] = 0;
	end
	
		total_errors = 0;
	
	// I don't think we need the other code
	
	busdrive = 0;
	MBUS.AddrValid = 0;
	MBUS.rw = 0;
end: setup


// apply test cases to the model
initial begin: stimulus
    $display("ECE 571 Fall 2021: (HW #3) Processor simulator for Memory controller testbench - Yashodhan Wagle (ywagle@pdx.edu)");
    $display("Sources: %s\n", getenv("PWD"));
   
    // ADD YOUR CODE HERE
	//1. first 16 locations of memory
	//2. reading those locations
	//3. writing to the top of the memory and read it back
	//4. write to the top of the memory and read it back using wraparound technique
	//4. write to the first 4 locations at the wrong page

	//1. first 16 locations
	wait(resetH == 0)
	$display("Writing to the first 16 locations of the memory");
	CPU_wrReq(MEMPAGE1, 12'h000,16'h0012, 16'h0014, 16'h0016, 16'h0018);
	CPU_wrReq(MEMPAGE1, 12'h030,16'h00AA, 16'h00AC, 16'h00AE, 16'h00AF);
	CPU_wrReq(MEMPAGE1, 12'h023,16'h0005, 16'h0000, 16'h0001, 16'h000B);
	CPU_wrReq(MEMPAGE1, 12'h0CD,16'h0009, 16'h0003, 16'h0006, 16'h0007);
	
	//2. reading those locations
	$display("\nReading them from the memory");
	CPU_rdReq(MEMPAGE1, 12'h110 );
	CPU_rdReq(MEMPAGE1, 12'hAA0 );	
	CPU_rdReq(MEMPAGE1, 12'h0F0 );
	CPU_rdReq(MEMPAGE1, 12'h700 );
	
	//3. writing to the stop of the memory and read it back
	$display("writing to the top of the memory and read it back");
	CPU_wrReq(MEMPAGE1, 12'h215,16'h0101,16'h0104, 16'h01AA,16'h123A);
	CPU_rdReq(MEMPAGE1,12'h215);
	
	//4. Write to the top of the memory and read it back using wraparound technique
	$display("Write to the top of the memory and read it back using wraparound technique");
	CPU_wrReq(MEMPAGE1,12'h0FF,16'hAAAA,16'hBBBB, 16'hCCCC,16'h00FF );
	CPU_rdReq(MEMPAGE1,12'h0FF);
		
	//5. write to the first 4 locations at the wrong page
	$display("write to the first 4 locations at the wrong page");
	CPU_wrReq(MEMPAGE2, 12'h111,16'h0000,16'h0A00,16'h4AAA,16'hFFFF);
	CPU_rdReq(MEMPAGE1, 12'h111);	
	//testing till here
	
	//to find if the design has erros
	repeat(10) 	@ (posedge clk);
		if(total_errors== 0)	begin
			$display("Error-free code");	end
		else				begin
			$display("%d errors found in the code after completely testing.",total_errors); end 
			
	$display("End simulation of ECE 571 Fall 2021: (HW #3) Memory controller testbench - <Ramaa> (rgp2@pdx.edu)\n");	
	$stop;
end: stimulus

endprogram: processor
