`timescale 1ns/1ps

module tb_rojobot_controller ;

	localparam CLK_PERIOD = 10;

	localparam CLK_PERIOD_100	= CLK_PERIOD;
	localparam CLK_PERIOD_75	= CLK_PERIOD * 0.75;

	logic clk_100, clk_75, rstn;

	logic video_on, VGA_HS, VGA_VS;
	logic [11:0] pixel_row, pixel_column;

	logic VGA_R, VGA_G, VGA_B;
	
	rojo_if rojoif();
	rojobot_controller DUT( rojoif );

	dtg DTG (
		.clock			(clk_75),
		.rst			(~rstn),
		.horiz_sync		(VGA_HS),
		.vert_sync		(VGA_VS),
		.*						);

	assign rojoif.clk			= clk_100;
	assign rojoif.rstn			= rstn;
	assign rojoif.clk_75		= clk_75;

	assign rojoif.pixel_row		= pixel_row;
	assign rojoif.pixel_column	= pixel_column;
	assign rojoif.video_on		= video_on;

	assign VGA_R				= rojoif.VGA_R;
	assign VGA_G				= rojoif.VGA_G;
	assign VGA_B				= rojoif.VGA_B;

	initial begin
		clk_100 	= 0;

		forever	#(CLK_PERIOD_100 / 2)
				clk_100 = ~clk_100;
	end

	initial begin
		clk_75 	= 0;

		forever	#(CLK_PERIOD_75 / 2)
				clk_75 = ~clk_75;
	end
	
	initial begin
		rstn = 1;
		
		rojoif.debounced_SW = 0;	// Used for map_sel

		// WISHBONE Interface
		rojoif.wb_adr_i = 0;
		rojoif.wb_dat_i = 0;
		rojoif.wb_sel_i = 0;
		rojoif.wb_we_i 	= 0;
		rojoif.wb_cyc_i = 0;
		rojoif.wb_stb_i = 0;
		rojoif.wb_cti_i = 0;
		rojoif.wb_bte_i = 0;

		@(negedge clk_100) rstn = 0;
		@(negedge clk_100) rstn = 1;

		wait(pixel_row == 767)
		#(10*CLK_PERIOD_75) $stop;

	end
	
endmodule