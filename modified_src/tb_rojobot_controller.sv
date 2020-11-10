`timescale 1ns/1ns
module tb_rojobot_controller ;

	rojo_if rojoif();

	localparam CLK_PERIOD_100 = 40;
	localparam CLK_PERIOD_75 = 30;

	int i, j;

	rojobot_controller DUT( rojoif );

	initial begin
		rojoif.clk 		= 0;
		rojoif.rstn		= 1;

		forever	#(CLK_PERIOD_100 / 2)	rojoif.clk = ~rojoif.clk;
	end

	initial begin
		rojoif.clk_75 	= 0;

		forever	#(CLK_PERIOD_75 / 2)	rojoif.clk_75 = ~rojoif.clk_75;
	end
	
	initial begin
		rojoif.debounced_SW = 0;

		// WISHBONE Interface
		rojoif.wb_adr_i = 0;
		rojoif.wb_dat_i = 0;
		rojoif.wb_sel_i = 0;
		rojoif.wb_we_i 	= 0;
		rojoif.wb_cyc_i = 0;
		rojoif.wb_stb_i = 0;
		rojoif.wb_cti_i = 0;
		rojoif.wb_bte_i = 0;

		// VGA
		rojoif.pixel_column = 0;	// VGA screen column
		rojoif.pixel_row 	= 0;	// VGA screen row
		rojoif.video_on 	= 0;	// VGA signal for visible region

		#25 rojoif.rstn = 0;
		#25 rojoif.rstn = 1;

		#(10*CLK_PERIOD_75);
		for (i = 0; i < 768; i++) begin
			for (j = 0; j < 1024; j++) begin
				@(negedge rojoif.clk_75)
				rojoif.pixel_column = j;
				rojoif.pixel_row 	= i;
			end
		end
		#(10 * CLK_PERIOD_75) $stop;

	end
	
endmodule