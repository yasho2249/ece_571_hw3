//////////////////////////////////////////////////////////////
// ThreeAndOut_ex.sv - ThreeAndOut Example
//
// Author:	Roy Kravitz 
// Date:	05-Feb-2017
//
// Description:
// ------------
// Sample code from Example 6.5.3 in D. Thomas' book.  The code
// uses interfaces to specify a bus protocol (ThreeAndOut) that 
// uses a producer thread to send a 3 byte (24 bits) packet to a
// consumer thread that implements the receiving side of the
// ThreeAndOut protocol.
////////////////////////////////////////////////////////////////

// ThreeAndOut interface specification - wires in ThreeAndOut bus
interface ThreeAndOut
(
	input bit		clk, reset_L
);
	logic			StartNow;
	logic	[7:0]	data;
	
	modport master
	(
		output		StartNow,
					data,
		input		clk, reset_L
	);
	
	modport slave
	(
		input		StartNow,
					data,
					clk, reset_L
	);
endinterface: ThreeAndOut

// talker interface specification - hardware thread to send
// packet on ThreeAndOut bus using the ThreeAndOut protocol
interface talker(ThreeAndOut.master T);
	logic	[23:0]	saywhat;
	logic			speak = 0;
	
	enum {waitHere, first, second} st, ns;
	
	modport blab (import sendit);
	
	// task to send a packet on the ThreeAndOne bus
	task sendit (input logic [23:0] stuff);
		begin
			saywhat <= stuff;
			speak <= 1;
			@(posedge T.clk) speak <= 0;
		end
	endtask: sendit
	
	// FSM that implements the send portion of the ThreeAndOne protocol
	// Mealy machine implemented with the two always block method
	always_ff @(posedge T.clk, negedge T.reset_L) begin
		if (~T.reset_L)
			st <= waitHere;
		else
			st <= ns;
	end // FSM sequential block
	
	always_comb begin
		T.StartNow = 0;
		unique case (st)
			waitHere: begin
				ns = (speak) ? first : waitHere;
				T.StartNow = speak;
				T.data = (speak) ? saywhat[23:16] : 'bz;
			end
			
			first: begin
				ns = second;
				T.data = saywhat[15:8];
			end
			
			second: begin
				ns = waitHere;
				T.data = saywhat[7:0];
			end
		endcase
	end // FSM next state and output block
	
endinterface: talker

// producer module testbench - sends packets using the talker interface
module TBtalk
(
	ThreeAndOut.master T,
	talker.blab lips
);

initial begin
	repeat (4) @(posedge T.clk);
	lips.sendit(24'h012345);
	
	repeat (5) @(posedge T.clk);
	lips.sendit(24'hfedcba);
	@(posedge T.clk);
end // stimulus initial block

endmodule: TBtalk


// listener interface specification - hardware thread to receive
// a packet on ThreeAndOut bus using the ThreeAndOut protocol
interface listener (ThreeAndOut.slave L);
	logic[23:0]		IncomingMessage;
	bit				GotMessage;
	bit				ldLow, ldMid, ldHigh;
	
	modport audioIn (import hearit);
	
	enum {warten, eins, zwei} st, ns;
	
	task hearit(output logic [23:0]	words);
		begin
			@(posedge L.clk);
			while (~GotMessage)
				@(posedge L.clk);
			@(posedge L.clk);
			words = IncomingMessage;
		end
	endtask: hearit
	
	// packet buffer
	always_ff @(posedge L.clk) begin
		if (ldLow)
			IncomingMessage[7:0] = L.data;
		else if (ldMid)
			IncomingMessage[15:8] = L.data;
		else if (ldHigh)
			IncomingMessage[23:16] = L.data;
	end // packet buffer
	
	// FSM that implements the receive portion of the ThreeAndOne protocol
	// Mealy machine implemented with the two always block method
	always_ff @(posedge L.clk, negedge L.reset_L) begin
		if (~L.reset_L)
			st <= warten;
		else
			st <= ns;
	end // sequential block for FSM
	
	always_comb begin
		GotMessage = 0;
		ldLow = 0;
		ldMid = 0;
		ldHigh = 0;
		
		unique case (st)
			warten:	begin
				ns = (L.StartNow) ? eins : warten;
				ldHigh = (L.StartNow) ? 1 : 0;
			end
			
			eins:	begin
				ns = zwei;
				ldMid = 1;
			end
			
			zwei:	begin
				ns = warten;
				ldLow = 1;
				GotMessage = 1;
			end
		endcase
	end // FSM next state and output block
	
endinterface: listener

// consumer module testbench - receives packets using the listener interface
module TBlisten
(
	listener.audioIn ear
);

	logic	[23:0]	blahblah;
	
	// continously receives packets
	// hearit task blocks until full packet received
	always begin
		ear.hearit(blahblah);
		$display("%3d, Message is %h", $stime, blahblah);
	end // continously receive packets
endmodule: TBlisten


// top level model - instantiates a producer and consumer thread
module top;
	bit		clk, reset_L;
	
	// instantiate the ThreeAndOut bus interface
	ThreeAndOut TAO(clk, reset_L);
	
	// instantiate the talker (producer) and listener (consumer)
	talker tk(TAO.master);
	listener ls(TAO.slave);
	
	// instantiate the producer and consumer testbenches
	TBtalk TBT(TAO.master, tk.blab);
	TBlisten TBL(ls.audioIn);
	
	// let 'er rip
	initial begin
		clk = 0;
		reset_L = 0;
		reset_L <= #1 1;
		repeat (30) #5 clk = ~clk;
		#1 $stop;
	end
	
endmodule: top


	
	