/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2012 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/
// You must compile the wrapper file world_map.v when simulating
// the core, world_map. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

// The synthesis directives "translate_off/translate_on" specified below are
// supported by Xilinx, Mentor Graphics and Synplicity synthesis
// tools. Ensure they are correct for your synthesis tool(s).

`timescale 1ns/1ps

module world_map(
  clka,
  addra,
  douta,
  clkb,
  addrb,
  doutb,
  map_sel
);

input clka;
input [13 : 0] addra;
output [1 : 0] douta;
input clkb;
input [13 : 0] addrb;
output [1 : 0] doutb;
input [1:0] map_sel;

  wire [1:0] loop_douta, loop_doutb;
  wire [1:0] lr_douta, lr_doutb;
  wire [1:0] part_1_douta, part_1_doutb;

  assign {douta, doutb} = (map_sel == 2'b00) ? {part_1_douta, part_1_doutb} :
              ((map_sel == 2'b01) ? {loop_douta, loop_doutb} : 
                          {lr_douta, lr_doutb});

  world_map_part_1 part_1 (
    .clka(clka),
    .addra(addra),
    .douta(part_1_douta),
    .clkb(clkb),
    .addrb(addrb),
    .doutb(part_1_doutb));

  world_map_loop loop (
    .clka(clka),
    .addra(addra),
    .douta(loop_douta),
    .clkb(clkb),
    .addrb(addrb),
    .doutb(loop_doutb));

  world_map_lr lr (
    .clka(clka),
    .addra(addra),
    .douta(lr_douta),
    .clkb(clkb),
    .addrb(addrb),
    .doutb(lr_doutb));

endmodule
