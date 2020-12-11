interface Wishbone_if (
	input logic clk, rst
);

	localparam TIMEOUT = 10;

	logic	[15:2]	adr;			// Address port
	logic	[31:0]	dat_i, dat_o;	// Data input and output ports
	logic	[3:0]	sel;			// Data select
	logic			we;				// Write enable
	logic			cyc;			// Cycle
	logic			stb;			// Strobe
	logic			ack;			// Acknowledge
	logic			err;			// Error
	logic			rty;			// Retry
	logic	[2:0]	cti;			// Cycle Type Identifier
	logic	[1:0]	bte;			// Burst Type Extension

	modport master (
		input	clk, rst,
				dat_i,
				ack, err, rty,
		output	adr, dat_o,
				we, sel, stb, cyc,
				cti, bte
	);

	modport slave (
		input	clk, rst,
				adr, dat_i,
				we, sel, stb, cyc,
				cti, bte,
		output	dat_o,
				ack, err, rty	
	);

	task single_read(input logic [15:0] addr);
		@(posedge clk);
		adr		= addr >> 2;
		we		= 0;
		sel		= 4'b1111;	// Read 32 bits
		cyc		= 1;		// Start transaction
		stb		= 1;		// Start phase

		fork: read_timeout
			begin
				wait(ack);
				disable read_timeout;
			end

			begin
				repeat (TIMEOUT) @(posedge clk);
				$error("Read timed out without acknowledge");
				disable read_timeout;
			end
		join

		@(posedge clk);	// After receiving ACK
		adr		= 0;
		sel		= 0;
		stb		= 0;
		cyc		= 0;
	endtask : single_read

	task single_write(input logic [15:0] addr, logic [31:0] data);
		@(posedge clk);
		adr		= addr >> 2;
		dat_o	= data;
		we		= 1;
		sel		= 4'b1111;	// Write 32 bits
		cyc		= 1;		// Start transaction
		stb		= 1;		// Start phase

		fork: read_timeout
			begin
				wait(ack);
				disable read_timeout;
			end

			begin
				repeat (TIMEOUT) @(posedge clk);
				$error("Write timed out without acknowledge");
				disable read_timeout;
			end
		join

		@(posedge clk);	// After receiving ACK
		adr		= 0;
		dat_o	= 0;
		sel		= 0;
		we		= 0;
		stb		= 0;
		cyc		= 0;
	endtask : single_write


endinterface

/*
I would like to be able to see a WishBone simulation enough to 
bring up waveforms and test the pushbuttons added in 
simplebot and the control and status registers in Rojobot.  
It would be nice to verify the Rojobot handshake signal as well.  
From your comments, it sounds like the Rojobobot control register 
testing may be more difficult in Questa, so maybe do testing of that 
in Vivado simulation?

I would like to be able to at least see a task for write 
and read and be able to bring up waveforms so that somebody 
could verify they hooked up the bus correctly.  I actually 
think that the current read/write to the Rojobot control/status 
registers is not ideal and should be modified.  Some waveforms 
would be able to let me see if that is the case and try to fix it.

If we had something like this, the camera team could possibly use 
it to test their added I2C interface and make sure it is working 
or help debug it.  They are still running into challenges with that.

Maybe the read task could also do a check against a value and 
throw a warning/error message if it is not as expected. 
The write task could throw an error if it does not get an 
acknowledge at least.
*/