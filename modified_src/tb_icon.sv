`timescale 1ns/1ns

module tb_icon (  );

	rojo_ctrl_if ctrlif();

	robot_icon iconizer(ctrlif);

	int row, column;

	initial begin
		ctrlif.LocX_reg = 64;
		ctrlif.LocY_reg = 64;
		
		ctrlif.pixel_row 	= 0;
		ctrlif.pixel_column = 0;

		for (row = 0; row < 2**12; row++) begin
			for (column = 0; column < 2**12; column++) begin
				ctrlif.pixel_row 	= row;
				ctrlif.pixel_column = column;
				#5
				
				if ((ctrlif.pixel_row == 64) &
					(ctrlif.pixel_column == 65))
					assert (ctrlif.icon_value == 2'b11)
					else $error("FAIL: Incorrect value for front pixel");
				else if ((ctrlif.pixel_row >= 63) & (ctrlif.pixel_row <= 65) &
						(ctrlif.pixel_column >= 63) & (ctrlif.pixel_column <= 65))
					assert (ctrlif.icon_value == 2'b01)
					else $error("FAIL: Incorrect value for icon pixel");
				else
					assert (ctrlif.icon_value == 2'b00)
					else $error("FAIL: Incorrect value for non-icon pixel");
			end
		end
		$stop;
	end

endmodule