`include "rojo_if.svh"

/*
	TODO:
	1. Implement Wishbone interface for controller
	2. Check reset values for regs
	3. Icon module
	4. Scaler module
	5. rojobot31_0 reset
*/

module rojobot_controller ( rojo_if.ctrl rojoif );

	rojo_ctrl_if ctrlif();

	logic			Bot_Update_Reg;
	logic			Bot_Ack_Reg;
	logic	[31:0]	Bot_Status_Reg;
	logic	[7:0]	Bot_Control_Reg;
	logic	[7:0]	Bot_Config_Reg;		// Debounced switches


	logic			upd_sysregs;
	logic	[7:0]	LocX_reg, LocY_reg, Sensors_reg, BotInfo_reg;
	logic	[13:0]	robot_map_addr;
	logic	[1:0]	robot_map_data;

	logic 	[7:0]	addr_match;

	assign ctrlif.pixel_row 	= rojoif.pixel_row;
	assign ctrlif.pixel_column 	= rojoif.pixel_column;
	assign ctrlif.video_on 		= rojoif.video_on;
	assign ctrlif.LocX_reg		= LocX_reg;
	assign ctrlif.LocY_reg		= LocY_reg;
	assign ctrlif.BotInfo_reg	= BotInfo_reg;

	assign rojoif.VGA_R 		= ctrlif.VGA_R;
	assign rojoif.VGA_G 		= ctrlif.VGA_G;
	assign rojoif.VGA_B 		= ctrlif.VGA_B;

	// assign addr_match = rojoif.wb_adr_i[31:8] == 24'h000018 ? rojoif.wb_adr_i[7:0] : 0;
	assign addr_match = rojoif.wb_adr_i[7:0];

	assign Bot_Config_Reg = rojoif.debounced_SW;

	// Ack Control WB Example
	always_ff @(posedge rojoif.clk, negedge rojoif.rstn) begin
		if (~rojoif.rstn)	rojoif.wb_ack_o <= 0;
		else 				rojoif.wb_ack_o <= rojoif.wb_cyc_i & rojoif.wb_stb_i & !rojoif.wb_ack_o;
	end

	// Read Control WB Example
	always_ff @(posedge rojoif.clk, negedge rojoif.rstn) begin
		if (~rojoif.rstn)
			rojoif.wb_dat_o <= 32'h00_00_00_00;
		else begin
			case (addr_match)
				8'h0C: rojoif.wb_dat_o <= Bot_Status_Reg; 					// bot status
				8'h14: rojoif.wb_dat_o <= {31'h00_00_00_00, Bot_Update_Reg}; // update sync
			endcase
		end
	end

	// Write Control WB Example
	always_ff @(posedge rojoif.clk, negedge rojoif.rstn) begin
		if (~rojoif.rstn) begin
			Bot_Ack_Reg		<= 1'b0;
			Bot_Control_Reg	<= 8'h00;
		end	else if ( rojoif.wb_cyc_i & rojoif.wb_stb_i & rojoif.wb_we_i & !rojoif.wb_ack_o & rojoif.wb_sel_i[0] ) begin // Possibly rojoif.wb_ck_o instead.
			case (addr_match)
				8'h10: Bot_Control_Reg	<= rojoif.wb_dat_i[7:0];	//bot control
				8'h18: Bot_Ack_Reg  	<= rojoif.wb_dat_i[0];		// int ack
			endcase
		end
	end

	// Addresses for WB interface:
	//	1. Bot_Control_Reg: write MotCtl_in data to it
	//	2. Bot_Status_Reg: {LocX_reg,LocY_reg,Sensors_reg,BotInfo_Reg}
	//	3. Bot_Update_Reg: Polled to check IO_BotUpdt_Sync
	//	4. Bot_Ackowl_Reg: Write 1 to clear IO_BotUpdt_Sync

	// Assembly polls an address containing IO_BotUpdt_Sync for updates,
	// if an update is seen clear this register by writing 1 to the IO_INT_ACK address

	assign Bot_Status_Reg = {LocX_reg, LocY_reg, Sensors_reg, BotInfo_reg};

	always_ff @ (posedge rojoif.clk) begin: handshaking_ff
		if (Bot_Ack_Reg)
			Bot_Update_Reg <= 1'b0;
		else if (upd_sysregs)
			Bot_Update_Reg <= 1'b1;
		end


	rojobot31_0 robot (
		.MotCtl_in(Bot_Control_Reg),			// input wire [7 : 0] MotCtl_in
		.LocX_reg(LocX_reg),				// output wire [7 : 0] LocX_reg
		.LocY_reg(LocY_reg),				// output wire [7 : 0] LocY_reg
		.Sensors_reg(Sensors_reg),			// output wire [7 : 0] Sensors_reg
		.BotInfo_reg(BotInfo_reg),			// output wire [7 : 0] BotInfo_reg
		.worldmap_addr(robot_map_addr),		// output wire [13 : 0] worldmap_addr
		.worldmap_data(robot_map_data),		// input wire [1 : 0] worldmap_data
		.clk_in(rojoif.clk_75),					// input wire clk_in
		.reset(~rojoif.rstn),					// input wire reset
		.upd_sysregs(upd_sysregs),			// output wire upd_sysregs
		.Bot_Config_reg(Bot_Config_Reg)		// input wire [7 : 0] Bot_Config_reg
	);

	world_map map (
		.clka(rojoif.clk_75),
		.addra(robot_map_addr),
		.douta(robot_map_data),
		.clkb(rojoif.clk_75),
		.addrb(ctrlif.video_address),
		.doutb(ctrlif.map_value),
		.map_sel(rojoif.debounced_SW[14:13])
	);

	robot_icon iconizer ( ctrlif );

	vga_scaler scaler ( ctrlif );

	colorizer colourizer ( ctrlif );

endmodule

// Instantiate RoJoBot module
(* X_CORE_INFO = "rojobot31,Vivado 2020.1.1" *)
(* CHECK_LICENSE_TYPE = "rojobot31_0,rojobot31,{}" *)
(* IP_DEFINITION_SOURCE = "package_project" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module rojobot31_0 (
	MotCtl_in,
	LocX_reg,
	LocY_reg,
	Sensors_reg,
	BotInfo_reg,
	worldmap_addr,
	worldmap_data,
	clk_in,
	reset,
	upd_sysregs,
	Bot_Config_reg
);

	input 	wire	[7 : 0]		MotCtl_in;
	output 	wire	[7 : 0]		LocX_reg;
	output 	wire	[7 : 0]		LocY_reg;
	output 	wire	[7 : 0]		Sensors_reg;
	output 	wire	[7 : 0]		BotInfo_reg;
	output 	wire	[13 : 0]	worldmap_addr;
	input 	wire	[1 : 0]		worldmap_data;
	input 	wire				clk_in;
	(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME reset, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
	(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 reset RST" *)
	input	wire 				reset;
	output	wire 				upd_sysregs;
	input	wire	[7 : 0]		Bot_Config_reg;

	rojobot31 inst (
		.MotCtl_in(MotCtl_in),
		.LocX_reg(LocX_reg),
		.LocY_reg(LocY_reg),
		.Sensors_reg(Sensors_reg),
		.BotInfo_reg(BotInfo_reg),
		.worldmap_addr(worldmap_addr),
		.worldmap_data(worldmap_data),
		.clk_in(clk_in),
		.reset(reset),
		.upd_sysregs(upd_sysregs),
		.Bot_Config_reg(Bot_Config_reg)
	);

endmodule


module robot_icon ( rojo_ctrl_if.icon iconif );

	// TODO: Pixel row and column are on 1024x768 scale, X and Y are 128x128
	//		 Implement orientation

	/* -------------------------------------------------------------------------


	------------------------------------------------------------------------- */

	logic	[12:0]	scaled_X, scaled_Y;
	logic	[2:0]	orient;
	logic			icon_front;

	assign scaled_X = iconif.LocX_reg << 3;
	assign scaled_Y = iconif.LocY_reg * 6;
	assign orient 	= iconif.BotInfo_reg[2:0];

	typedef logic [7:0] pixel_t;

	const pixel_t DOWN [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h1,	8'h17,	8'h1e,	8'h17,	8'h2,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h4a,	8'h1e,	8'h29,	8'h4f,	8'h4b,	8'ha,	8'h00,	8'h00},
		{8'h00,	8'h40,	8'h52,	8'h3f,	8'h5e,	8'h63,	8'h5c,	8'h7,	8'h42,	8'h4e,	8'h9},
		{8'h00,	8'h51,	8'h56,	8'h38,	8'h20,	8'h20,	8'h4c,	8'h38,	8'h9,	8'h53,	8'h3f},
		{8'h00,	8'h21,	8'h2e,	8'h13,	8'h13,	8'h13,	8'h13,	8'h13,	8'h56,	8'h4d,	8'h8},
		{8'h00,	8'h4d,	8'h4d,	8'h65,	8'h58,	8'h5d,	8'h5a,	8'h61,	8'h21,	8'h46,	8'h00},
		{8'h00,	8'h2,	8'h46,	8'h64,	8'h1c,	8'h66,	8'h13,	8'h5f,	8'h3f,	8'h1,	8'h00},
		{8'h00,	8'h3c,	8'h3b,	8'h49,	8'h57,	8'h60,	8'h54,	8'h1c,	8'h3e,	8'h3a,	8'h1},
		{8'h00,	8'h27,	8'h39,	8'hf,	8'h3b,	8'h3f,	8'h3d,	8'hf,	8'hb,	8'h27,	8'h7},
		{8'h00,	8'h4e,	8'h5,	8'he,	8'h11,	8'h1a,	8'h11,	8'hf,	8'h3,	8'h53,	8'h3f},
		{8'h00,	8'h48,	8'h1f,	8'h37,	8'h41,	8'h62,	8'h41,	8'h37,	8'h43,	8'h50,	8'h3f},
		{8'h00,	8'h2,	8'h45,	8'hd,	8'h59,	8'h35,	8'h32,	8'hd,	8'h44,	8'h2,	8'h00},
		{8'h00,	8'h00,	8'h47,	8'h55,	8'h4,	8'h4,	8'h9,	8'h5b,	8'h12,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h1,	8'h1,	8'h00,	8'h1,	8'h1,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t UP [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h2,	8'h17,	8'h17,	8'h17,	8'h2,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h4,	8'ha,	8'h1e,	8'h2a,	8'h29,	8'h24,	8'h1e,	8'h3,	8'hb,	8'h1},
		{8'h00,	8'h1c,	8'ha,	8'h24,	8'h1e,	8'hc,	8'ha,	8'h1e,	8'h17,	8'h28,	8'h13},
		{8'h00,	8'h21,	8'h30,	8'h14,	8'hc,	8'h1e,	8'h24,	8'h1d,	8'h2c,	8'h21,	8'h8},
		{8'h00,	8'h34,	8'h7,	8'h2f,	8'ha,	8'h1e,	8'h2a,	8'h25,	8'h8,	8'h31,	8'h8},
		{8'h00,	8'h2,	8'h36,	8'h20,	8'h2,	8'h14,	8'h24,	8'h1e,	8'h22,	8'h22,	8'h00},
		{8'h00,	8'h2,	8'h26,	8'h38,	8'h2e,	8'h14,	8'h1e,	8'h15,	8'h13,	8'h2,	8'h00},
		{8'h00,	8'h27,	8'h3,	8'h6,	8'h2e,	8'h1b,	8'h14,	8'h16,	8'h2,	8'h2b,	8'h7},
		{8'h00,	8'h2b,	8'h5,	8'he,	8'h10,	8'h10,	8'h10,	8'hf,	8'h3,	8'h21,	8'h00},
		{8'h00,	8'h7,	8'h33,	8'h18,	8'h10,	8'h11,	8'h1a,	8'hf,	8'h23,	8'h1,	8'h00},
		{8'h00,	8'h2,	8'h18,	8'h32,	8'h35,	8'he,	8'h19,	8'h37,	8'h1f,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h4,	8'hd,	8'h18,	8'h35,	8'h32,	8'hd,	8'h3,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h12,	8'h2d,	8'h4,	8'h4,	8'h9,	8'h2d,	8'h7,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h1,	8'h1,	8'h00,	8'h1,	8'h1,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t RIGHT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h1,	8'h68,	8'h25,	8'h42,	8'h69,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h17,	8'h2a,	8'h29,	8'h75,	8'h83,	8'h8,	8'h6d,	8'h00},
		{8'h00,	8'h73,	8'h14,	8'h17,	8'h1e,	8'h79,	8'h82,	8'h2c,	8'h7c,	8'h80,	8'h9},
		{8'h00,	8'h24,	8'h1e,	8'h17,	8'h4e,	8'h7b,	8'h20,	8'h2e,	8'h81,	8'h2e,	8'h4},
		{8'h00,	8'h1e,	8'h17,	8'h2,	8'h64,	8'h48,	8'h36,	8'h13,	8'h13,	8'h21,	8'h00},
		{8'h00,	8'h6b,	8'h67,	8'h2,	8'h34,	8'h48,	8'h36,	8'h78,	8'h40,	8'h57,	8'h1},
		{8'h00,	8'h00,	8'h00,	8'h52,	8'h71,	8'h31,	8'h1b,	8'h7f,	8'h7f,	8'h2b,	8'h1},
		{8'h00,	8'h00,	8'h00,	8'h67,	8'h5,	8'h49,	8'h2b,	8'h2b,	8'hb,	8'h4e,	8'h3f},
		{8'h00,	8'h00,	8'h00,	8'h67,	8'h10,	8'h5,	8'h3,	8'h3b,	8'h11,	8'h6a,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h72,	8'h3c,	8'h21,	8'h27,	8'h3a,	8'h3b,	8'h6e,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h70,	8'h7a,	8'h77,	8'h7e,	8'h4e,	8'h7d,	8'h6f,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h1,	8'h6a,	8'h53,	8'h5f,	8'h48,	8'h6c,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h2,	8'h8,	8'h3f,	8'h74,	8'h7,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h7,	8'h76,	8'h7b,	8'h21,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t UP_RIGHT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h1,	8'h00,	8'h1,	8'h68,	8'h25,	8'h25,	8'h15,	8'h67,	8'h00,	8'h00},
		{8'h00,	8'h7f,	8'h2,	8'h89,	8'h2a,	8'h29,	8'h24,	8'h1e,	8'h14,	8'h40,	8'h00},
		{8'h00,	8'h31,	8'h8,	8'h69,	8'h4f,	8'h1e,	8'h1e,	8'h6b,	8'h8,	8'h53,	8'h00},
		{8'h00,	8'h4d,	8'ha,	8'h1e,	8'h42,	8'ha,	8'h7,	8'h2c,	8'h4e,	8'h4d,	8'h00},
		{8'h00,	8'h2,	8'h25,	8'h29,	8'h24,	8'h1e,	8'h2,	8'h7,	8'h34,	8'h4d,	8'h00},
		{8'h00,	8'h2,	8'h2a,	8'h24,	8'h42,	8'h1c,	8'h81,	8'h8c,	8'h4d,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h86,	8'h1e,	8'h17,	8'h8c,	8'h38,	8'h52,	8'h2,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h6e,	8'h17,	8'h13,	8'h2e,	8'h85,	8'h40,	8'h4d,	8'h77,	8'h00},
		{8'h00,	8'h2,	8'h21,	8'h6c,	8'h3b,	8'h3b,	8'h3e,	8'h46,	8'h4d,	8'h8,	8'h00},
		{8'h00,	8'h00,	8'h5,	8'hf,	8'h1a,	8'h11,	8'h3e,	8'h40,	8'h2b,	8'h2b,	8'h7},
		{8'h00,	8'h1,	8'h1f,	8'h8a,	8'h1a,	8'hf,	8'he,	8'h3e,	8'h8,	8'h8,	8'h00},
		{8'h00,	8'h1,	8'h87,	8'h35,	8'h8b,	8'h8b,	8'h8b,	8'h35,	8'h18,	8'h84,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h4,	8'h88,	8'h88,	8'h1f,	8'h4,	8'h4,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h1,	8'h1,	8'h2,	8'h76,	8'h76,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t DOWN_RIGHT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h2,	8'h2,	8'h42,	8'h25,	8'h42,	8'h69,	8'h00,	8'h1,	8'h00},
		{8'h00,	8'h2,	8'h17,	8'h8e,	8'h24,	8'h93,	8'h96,	8'h9b,	8'h90,	8'h28,	8'h00},
		{8'h00,	8'h95,	8'h8,	8'h42,	8'h5e,	8'h82,	8'h71,	8'h92,	8'h81,	8'h92,	8'h00},
		{8'h00,	8'h97,	8'h1c,	8'h91,	8'h20,	8'h20,	8'h81,	8'h36,	8'h8c,	8'h3f,	8'h00},
		{8'h00,	8'h94,	8'h94,	8'h52,	8'h36,	8'h13,	8'h13,	8'h4d,	8'h9a,	8'h4d,	8'h00},
		{8'h00,	8'h1,	8'h94,	8'h4d,	8'h4e,	8'h9e,	8'h98,	8'h60,	8'h3f,	8'h46,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h94,	8'h99,	8'h9d,	8'h40,	8'h5f,	8'h94,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h5,	8'h41,	8'h2b,	8'h2b,	8'h1c,	8'h2,	8'h46,	8'h00},
		{8'h00,	8'h00,	8'h8,	8'h40,	8'hf,	8'he,	8'h3b,	8'hf,	8'h10,	8'h7,	8'h00},
		{8'h00,	8'h00,	8'h3f,	8'h2b,	8'h4,	8'he,	8'h8d,	8'h11,	8'h8f,	8'h2,	8'h00},
		{8'h00,	8'h00,	8'h2,	8'h8,	8'h4,	8'he,	8'h19,	8'h37,	8'h1f,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h1c,	8'h9c,	8'h40,	8'h35,	8'h35,	8'h23,	8'h44,	8'h1,	8'h00},
		{8'h00,	8'h00,	8'h1,	8'h3f,	8'h2,	8'h4,	8'h4,	8'h3,	8'h7,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h74,	8'h76,	8'h12,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};
	
	const pixel_t DOWN_LEFT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h1,	8'h00,	8'h69,	8'h42,	8'h25,	8'h42,	8'h2,	8'h2,	8'h00,	8'h00},
		{8'h00,	8'h28,	8'h90,	8'h9b,	8'h96,	8'h93,	8'h24,	8'h8e,	8'h17,	8'h2,	8'h00},
		{8'h00,	8'h92,	8'h81,	8'h92,	8'h71,	8'h82,	8'h5e,	8'h42,	8'h8,	8'h95,	8'h00},
		{8'h00,	8'h3f,	8'h8c,	8'h36,	8'h81,	8'h20,	8'h20,	8'h91,	8'h1c,	8'h97,	8'h00},
		{8'h00,	8'h4d,	8'h9a,	8'h4d,	8'h13,	8'h13,	8'h36,	8'h52,	8'h94,	8'h94,	8'h00},
		{8'h00,	8'h46,	8'h3f,	8'h60,	8'h98,	8'h9e,	8'h4e,	8'h4d,	8'h94,	8'h1,	8'h00},
		{8'h00,	8'h1,	8'h94,	8'h5f,	8'h40,	8'h9d,	8'h99,	8'h94,	8'h1,	8'h00,	8'h00},
		{8'h00,	8'h46,	8'h2,	8'h1c,	8'h2b,	8'h2b,	8'h41,	8'h5,	8'h1,	8'h00,	8'h00},
		{8'h00,	8'h7,	8'h10,	8'hf,	8'h3b,	8'he,	8'hf,	8'h40,	8'h8,	8'h00,	8'h00},
		{8'h00,	8'h2,	8'h8f,	8'h11,	8'h8d,	8'he,	8'h4,	8'h2b,	8'h3f,	8'h00,	8'h00},
		{8'h00,	8'h1,	8'h1f,	8'h37,	8'h19,	8'he,	8'h4,	8'h8,	8'h2,	8'h00,	8'h00},
		{8'h00,	8'h1,	8'h44,	8'h23,	8'h35,	8'h35,	8'h40,	8'h9c,	8'h1c,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h7,	8'h3,	8'h4,	8'h4,	8'h2,	8'h3f,	8'h1,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h12,	8'h76,	8'h74,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t LEFT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h69,	8'h42,	8'h25,	8'h68,	8'h1,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h6d,	8'h8,	8'h83,	8'h75,	8'h29,	8'h2a,	8'h17,	8'h1,	8'h00,	8'h00},
		{8'h9,	8'h80,	8'h7c,	8'h2c,	8'h82,	8'h79,	8'h1e,	8'h17,	8'h14,	8'h73,	8'h00},
		{8'h4,	8'h2e,	8'h81,	8'h2e,	8'h20,	8'h7b,	8'h4e,	8'h17,	8'h1e,	8'h24,	8'h00},
		{8'h00,	8'h21,	8'h13,	8'h13,	8'h36,	8'h48,	8'h64,	8'h2,	8'h17,	8'h1e,	8'h00},
		{8'h1,	8'h57,	8'h40,	8'h78,	8'h36,	8'h48,	8'h34,	8'h2,	8'h67,	8'h6b,	8'h00},
		{8'h1,	8'h2b,	8'h7f,	8'h7f,	8'h1b,	8'h31,	8'h71,	8'h52,	8'h00,	8'h00,	8'h00},
		{8'h3f,	8'h4e,	8'hb,	8'h2b,	8'h2b,	8'h49,	8'h5,	8'h67,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h6a,	8'h11,	8'h3b,	8'h3,	8'h5,	8'h10,	8'h67,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h6e,	8'h3b,	8'h3a,	8'h27,	8'h21,	8'h3c,	8'h72,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h6f,	8'h7d,	8'h4e,	8'h7e,	8'h77,	8'h7a,	8'h70,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h6c,	8'h48,	8'h5f,	8'h53,	8'h6a,	8'h1,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h7,	8'h74,	8'h3f,	8'h8,	8'h2,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h21,	8'h7b,	8'h76,	8'h7,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	const pixel_t UP_LEFT [16][11] = '{
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h67,	8'h15,	8'h25,	8'h25,	8'h68,	8'h1,	8'h00,	8'h1,	8'h00},
		{8'h00,	8'h40,	8'h14,	8'h1e,	8'h24,	8'h29,	8'h2a,	8'h89,	8'h2,	8'h7f,	8'h00},
		{8'h00,	8'h53,	8'h8,	8'h6b,	8'h1e,	8'h1e,	8'h4f,	8'h69,	8'h8,	8'h31,	8'h00},
		{8'h00,	8'h4d,	8'h4e,	8'h2c,	8'h7,	8'ha,	8'h42,	8'h1e,	8'ha,	8'h4d,	8'h00},
		{8'h00,	8'h4d,	8'h34,	8'h7,	8'h2,	8'h1e,	8'h24,	8'h29,	8'h25,	8'h2,	8'h00},
		{8'h00,	8'h00,	8'h4d,	8'h8c,	8'h81,	8'h1c,	8'h42,	8'h24,	8'h2a,	8'h2,	8'h00},
		{8'h00,	8'h1,	8'h2,	8'h52,	8'h38,	8'h8c,	8'h17,	8'h1e,	8'h86,	8'h00,	8'h00},
		{8'h00,	8'h77,	8'h4d,	8'h40,	8'h85,	8'h2e,	8'h13,	8'h17,	8'h6e,	8'h00,	8'h00},
		{8'h00,	8'h8,	8'h4d,	8'h46,	8'h3e,	8'h3b,	8'h3b,	8'h6c,	8'h21,	8'h2,	8'h00},
		{8'h7,	8'h2b,	8'h2b,	8'h40,	8'h3e,	8'h11,	8'h1a,	8'hf,	8'h5,	8'h00,	8'h00},
		{8'h00,	8'h8,	8'h8,	8'h3e,	8'he,	8'hf,	8'h1a,	8'h8a,	8'h1f,	8'h1,	8'h00},
		{8'h00,	8'h84,	8'h18,	8'h35,	8'h8b,	8'h8b,	8'h8b,	8'h35,	8'h87,	8'h1,	8'h00},
		{8'h00,	8'h1,	8'h4,	8'h4,	8'h1f,	8'h88,	8'h88,	8'h4,	8'h1,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h76,	8'h76,	8'h2,	8'h1,	8'h1,	8'h00,	8'h00,	8'h00,	8'h00},
		{8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00,	8'h00}};

	always_comb begin
		iconif.icon_value = 0;

		if ((iconif.pixel_row >= (scaled_Y)) & (iconif.pixel_row <= (scaled_Y + 15)) &
			(iconif.pixel_column >= (scaled_X)) & (iconif.pixel_column <= (scaled_X + 10))) begin

			unique case(orient)
				0:	iconif.icon_value = UP			[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				1:	iconif.icon_value = UP_RIGHT	[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				2:	iconif.icon_value = RIGHT		[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				3:	iconif.icon_value = DOWN_RIGHT	[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				4:	iconif.icon_value = DOWN		[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				5:	iconif.icon_value = DOWN_LEFT	[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				6:	iconif.icon_value = LEFT		[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
				7:	iconif.icon_value = UP_LEFT		[iconif.pixel_row - scaled_Y][iconif.pixel_column - scaled_X];
			endcase
		end

		// if (icon_front)	// Front pixel w.r.t orientation
		// 	iconif.icon_value = 2'b11;
		// else if ((iconif.pixel_row >= (scaled_Y - 2)) & (iconif.pixel_row <= (scaled_Y + 2)) &
		// 		(iconif.pixel_column >= (scaled_X - 2)) & (iconif.pixel_column <= (scaled_X + 2)))
		// 	iconif.icon_value = 2'b01;

	end

endmodule


module vga_scaler ( rojo_ctrl_if.scaler scalerif );

	logic [6:0] pixel_column;	// Scaled Row Value
	logic [6:0] pixel_row;		// Scaled Column Value

	// 1024x768 = 1024 columns, 768 rows

	assign pixel_column = scalerif.pixel_column >> 3;
	assign pixel_row 	= scalerif.pixel_row / 6;

	assign scalerif.video_address = {pixel_row, pixel_column};

endmodule


module colorizer ( rojo_ctrl_if.color colorif );

	/* -------------------------------------------------------------------------
						|  World |  Icon  |    Color     |
						----------------------------------
						|	00	 | 	 00	  |	 Background  |
						|	01	 |	 00   |  Black line  |
						|	10   |	 00	  | Obstruction  |
						|	11   |   00   |   Reserved   |
						|	x	 |   01	  | Icon color 1 |
						|	x	 |   10	  | Icon color 2 |
						|	x	 |   11	  | Icon color 3 |

	Icon colors are 12-bit values, colorizer output must be 0 when video_on is 0
	----------------------------------------------------------------------------- */

	typedef logic [11:0] colors_t;

	localparam colors_t MAP_COLORS[4] =
		'{12'h0F0,	// Background
		  12'h000,	// Black line
		  12'hF00,	// Obstruction
		  12'hF0F};

	// localparam colors_t ICON_COLORS[4] =
	// 	'{12'h000,
	// 	  12'h00F,
	// 	  12'h0F0,
	// 	  12'hF00};

	localparam colors_t ICON_COLORS[159] = {
		12'h0,		12'h133,	12'h222,	12'h232,	12'h233,	12'h243,	12'h253,	12'h322,	12'h332,	12'h333,	12'h342,	12'h343,	12'h351,	12'h365,	12'h396,
		12'h3a6,	12'h3b6,	12'h3c6,	12'h422,	12'h433,	12'h461,	12'h462,	12'h463,	12'h471,	12'h496,	12'h4a6,	12'h4d7,	12'h534,	12'h543,	12'h573,
		12'h591,	12'h595,	12'h635,	12'h642,	12'h645,	12'h695,	12'h6a1,	12'h6a2,	12'h735,	12'h752,	12'h754,	12'h7b1,	12'h7b2,	12'h852,	12'h951,
		12'ha12,	12'ha48,	12'ha50,	12'ha51,	12'ha62,	12'hab4,	12'hab5,	12'hb62,	12'hbc4,	12'hc59,	12'hdc4,	12'he6b,	12'h244,	12'h374,	12'h375,
		12'h384,	12'h385,	12'h386,	12'h432,	12'h443,	12'h453,	12'h481,	12'h485,	12'h522,	12'h533,	12'h542,	12'h631,	12'h643,	12'h652,	12'h661,
		12'h681,	12'h736,	12'h742,	12'h753,	12'h7a1,	12'h853,	12'h854,	12'h947,	12'h964,	12'ha74,	12'hb31,	12'hb58,	12'hb75,	12'hba9,	12'hbb4,
		12'hbbb,	12'hc41,	12'hc70,	12'hc73,	12'hd70,	12'hd84,	12'hd85,	12'hda8,	12'hdd4,	12'he80,	12'he96,	12'hedb,	12'hfa6,	12'h122,	12'h242,
		12'h352,	12'h354,	12'h361,	12'h364,	12'h434,	12'h442,	12'h464,	12'h475,	12'h532,	12'h553,	12'h582,	12'h622,	12'h680,	12'h812,	12'h963,
		12'h999,	12'ha80,	12'ha93,	12'hb50,	12'hb59,	12'hba3,	12'hc84,	12'hc85,	12'hd5a,	12'he5a,	12'he70,	12'hf70,	12'h254,	12'h344,	12'h452,
		12'h585,	12'h596,	12'h692,	12'h6a6,	12'h7a5,	12'ha47,	12'h3d6,	12'h581,	12'h6a5,	12'h744,	12'h841,	12'h846,	12'h8a1,	12'h952,	12'ha75,
		12'ha91,	12'hb74,	12'hbaa,	12'hc72,	12'hccb,	12'hd60,	12'he95,	12'heca,	12'hecb};

	always_comb begin
		if (~colorif.video_on)
			{colorif.VGA_R, colorif.VGA_G, colorif.VGA_B} = '0;
		else if (colorif.icon_value)
			{colorif.VGA_R, colorif.VGA_G, colorif.VGA_B} = ICON_COLORS[colorif.icon_value];
		else
			{colorif.VGA_R, colorif.VGA_G, colorif.VGA_B} = MAP_COLORS[colorif.map_value];
	end

endmodule