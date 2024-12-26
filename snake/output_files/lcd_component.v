module lcd_component(
  input CLOCK_50,	
//	LCD 模块 16X2
  output LCD_ON,	// LCD 开关
  output LCD_BLON,	// LCD 背光开关
  output LCD_RW,	// LCD 读/写选择
  output LCD_EN,	
  output LCD_RS,	// LCD 命令/数据选择，0 = 命令，1 = 数据
  inout [7:0] LCD_DATA,	
  input [2:0] mess, 
  input [7:0] SW, 
  output [6:0] HEX0, 
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [6:0] HEX6,
  output [6:0] HEX7
);

//	所有的 inout 端口都设置为三态
assign	GPIO_0		=	36'hzzzzzzzzz;
assign	GPIO_1		=	36'hzzzzzzzzz;

// 重置信号延迟，给外设初始化一些时间		
wire DLY_RST;
reset_delay r0(	.iCLK(CLOCK_50), .oRESET(DLY_RST) );

// 打开 LCD
assign	LCD_ON		=	1'b1;
assign	LCD_BLON	=	1'b1;


wire [1:0] isServer = SW[1:0]; 

lcd_messages u1(
   
   .iCLK(CLOCK_50),
   .iRST_N(DLY_RST),
   
   .LCD_DATA(LCD_DATA),
   .LCD_RW(LCD_RW),
   .LCD_EN(LCD_EN),
   .LCD_RS(LCD_RS),
   .mess(mess),
   .isServer(isServer) 
);



endmodule
