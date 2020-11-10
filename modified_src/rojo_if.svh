interface rojo_if;

    // controller --------------------------------------------------------------------------------
	// System
	logic			clk;			// 100MHz clock
	logic			rstn;			// reset active low
	logic			clk_75;			// 75MHz clock
	logic	[15:0]	debounced_SW;	// the switches

	// WISHBONE Interface
	logic	[31:0]	wb_adr_i;
	logic	[31:0]	wb_dat_i;
	logic	[3:0]	wb_sel_i;
	logic			wb_we_i;
	logic			wb_cyc_i;
	logic			wb_stb_i;
	logic	[2:0]	wb_cti_i;
	logic	[1:0]	wb_bte_i;
	logic	[31:0]	wb_dat_o;
	logic			wb_ack_o;
	logic			wb_err_o;
	logic			wb_rtry_o;

	// VGA
	logic	[11:0]	pixel_column;	// VGA screen column
	logic	[11:0]	pixel_row;		// VGA screen row
	logic			video_on;		// VGA signal for visible region
	logic	[3:0]	VGA_R;			// VGA red channel
	logic	[3:0]	VGA_G;			// VGA green channel
	logic	[3:0]	VGA_B;			// VGA blue channel

	modport ctrl (
		// System
		input	clk,
		input	rstn,
		input	clk_75,
		input	debounced_SW,

		// WISHBONE Interface
		input	wb_adr_i,
		input	wb_dat_i,
		input	wb_sel_i,
		input	wb_we_i,
		input	wb_cyc_i,
		input	wb_stb_i,
		input	wb_cti_i,
		input	wb_bte_i,
		output	wb_dat_o,
		output	wb_ack_o,
		output	wb_err_o,
		output	wb_rtry_o,

		// DTG
		input	pixel_column,
		input	pixel_row,
		input	video_on,

		// VGA
		output	VGA_R,
		output	VGA_G,
		output	VGA_B
	);

endinterface

interface rojo_ctrl_if;
	
	// robot_icon_if ------------------------------------------------------------------------------
	logic	[11:0]	pixel_column;	// VGA screen column
	logic	[11:0]	pixel_row;		// VGA screen row
	logic 	[7:0]	LocX_reg;
	logic 	[7:0]	LocY_reg;
	logic 	[7:0]	BotInfo_reg;
	logic	[7:0]	icon_value;

	// vga_scaler -------------------------------------------------------------------------------------
	logic	[13:0]	video_address;				// concatenation of {world row, world column}
	logic			out_of_map;					// indicate if the given pixel coordinates out-of-map (1) or not (0)

	// colorizer -----------------------------------------------------------------------------------
	logic			video_on;
	logic	[1:0]	map_value;
	logic	[1:0]	title_color;
	logic	[3:0]	VGA_R;			// VGA red channel
	logic	[3:0]	VGA_G;			// VGA green channel
	logic	[3:0]	VGA_B;			// VGA blue channel


	modport icon (
		// DTG
		input	pixel_row,
		input	pixel_column,

		// Rojobot
		input	LocX_reg,
		input	LocY_reg,
		input	BotInfo_reg,

		// Output
		output	icon_value
	);

	modport scaler (
		// DTG
		input	pixel_row, pixel_column,

		// Output
		output	video_address,
		output	out_of_map
	);

	modport color (
		// Icon
		input	icon_value,

		// World map
		input	map_value,

		// DTG
		input	video_on,

		// Output
		output	VGA_R,
		output	VGA_G,
		output	VGA_B
	);
	
endinterface