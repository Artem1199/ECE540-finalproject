module tb_rvfpga;
	logic			clk;
	logic			rstn;
	logic	[12:0]	ddram_a;
	logic	[2:0]	ddram_ba;
	logic			ddram_ras_n;
	logic			ddram_cas_n;
	logic			ddram_we_n;
	logic			ddram_cs_n;
	logic	[1:0]	ddram_dm;
	wire	[15:0]	ddram_dq;
	wire	[1:0]	ddram_dqs_p;
	wire	[1:0]	ddram_dqs_n;
	logic			ddram_clk_p;
	logic			ddram_clk_n;
	logic			ddram_cke;
	logic			ddram_odt;
	logic			o_flash_cs_n;
	logic			o_flash_mosi;
	logic			i_flash_miso;
	logic			i_uart_rx;
	logic			o_uart_tx;
	wire	[15:0]	i_sw;
	wire			BTNC, BTNU, BTNL, BTNR, BTND;
	logic		[15:0]	o_led;
	logic		[7:0]	AN;
	logic				DP, CA, CB, CC, CD, CE, CF, CG;
	logic			o_accel_cs_n;
	logic			o_accel_mosi;
	logic			i_accel_miso;
	logic			accel_sclk;

	logic 	[3:0]	VGA_R, VGA_G, VGA_B;
	logic			VGA_HS, VGA_VS;

	initial begin
	$assertoff;
		clk = 0;
		rstn = 1;

		forever #5 clk = ~clk;
	end

	initial begin
	#5 rstn = 0;
	#5 rstn = 1;
	end

	rvfpga DUT (.*);
	
endmodule