module world_map_part_1 (clka, addra, douta, clkb, addrb, doutb);

	input clka;
	input [13 : 0] addra;
	output [1 : 0] douta;
	input clkb;
	input [13 : 0] addrb;
	output [1 : 0] doutb;

	// (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.1.1" *)
	// module map_part_1(clka, wea, addra, dina, douta, clkb, web, addrb, dinb, doutb)
	// /* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[13:0],dina[13:0],douta[13:0],clkb,web[0:0],addrb[13:0],dinb[13:0],doutb[13:0]" */;
	// 	input clka;
	// 	input [0:0]wea;
	// 	input [13:0]addra;
	// 	input [13:0]dina;
	// 	output [13:0]douta;
	// 	input clkb;
	// 	input [0:0]web;
	// 	input [13:0]addrb;
	// 	input [13:0]dinb;
	// 	output [13:0]doutb;
	// endmodule

	map_part_1 map (
		.clka(clka),    // input wire clka
		.wea(0),      // input wire [0 : 0] wea
		.addra(addra),  // input wire [13 : 0] addra
		.dina(0),    // input wire [13 : 0] dina
		.douta(douta),  // output wire [13 : 0] douta
		.clkb(clkb),    // input wire clkb
		.web(0),      // input wire [0 : 0] web
		.addrb(addrb),  // input wire [13 : 0] addrb
		.dinb(0),    // input wire [13 : 0] dinb
		.doutb(doutb)  // output wire [13 : 0] doutb
	);

endmodule