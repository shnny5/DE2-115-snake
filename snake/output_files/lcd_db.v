 
`timescale 1ns/1ns
 
module lcd_db (); /* this is automatically generated */
 
	reg rst_n;
	reg clk;
 
	wire       lcd_rs;
	wire       lcd_rw;
	wire       lcd_en;
	wire [7:0] lcd_data;
 
	lcd1602 inst_lcd
		(
			.clk      (clk),
			.rst_n    (rst_n),
			.lcd_rs   (lcd_rs),
			.lcd_rw   (lcd_rw),
			.lcd_en   (lcd_en),
			.lcd_data (lcd_data)
		);
 
	initial clk = 0;
	always #10 clk = ~clk;
 
	initial begin
		#1;
		rst_n = 0;
		#200;
		rst_n = 1;
		#200;
 
 
		#100000000;
		$stop;
 
	end
 
endmodule