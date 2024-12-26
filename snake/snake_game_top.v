module snake_game_top(
    input CLOCK_50,          
    input [3:0] KEY,         
    input [17:0] SW,         
    output [8:0] LEDG,       
    output VGA_CLK,          
    output VGA_HS,           // 行信号
    output VGA_VS,           // 场信号
    output VGA_BLANK_N,      // 消隐信号
    output VGA_SYNC_N,       // 同步信号
    output [7:0] VGA_R,      // 红
    output [7:0] VGA_G,      // 绿
    output [7:0] VGA_B,      // 蓝
    output [35:0] GPIO,      // 引脚电压输出
    // LCD 接口
    output [7:0] LCD_DATA,   // LCD数据
    output LCD_RW,           // LCD读写控制
    output LCD_EN,           // LCD使能
    output LCD_RS,           // LCD数据/指令选择
    output LCD_ON,           // LCD电源
    output LCD_BLON,         // LCD背光
    // 七段数码管接口
    output [6:0] HEX0,       // 个位
    output [6:0] HEX1,       // 十位
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    output [6:0] HEX6,
    output [6:0] HEX7
);

    // 内部信号声明
    wire clk_25MHz;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire video_on;
    wire p_tick;
    wire buzzer_signal;
    
    // LCD相关信号
    wire [1:0] lcd_state;
    wire [31:0] game_timer;
    
    // 分数信号
    wire [6:0] score;

    // 时钟分频模块
    clock_divider clk_div (
        .clk_50MHz(CLOCK_50),
        .reset_n(!SW[0]),
        .clk_25MHz(clk_25MHz)
    );
    
    // VGA控制器
    vga_controller vga_ctrl (
        .clk_25MHz(clk_25MHz),
        .reset_n(!SW[0]),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .p_tick(p_tick)
    );
    
    // 游戏控制模块
    game_control game_ctrl (
        .clk_25MHz(clk_25MHz),
        .reset_n(!SW[0]),
        .key_up(!KEY[3]),
        .key_down(!KEY[2]),
        .key_left(!KEY[1]),
        .key_right(!KEY[0]),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),
        .p_tick(p_tick),
        .rgb_reg({VGA_R, VGA_G, VGA_B}),
        .buzzer_signal(buzzer_signal),
        .lcd_state(lcd_state),
        .game_timer(game_timer),
        .score_out(score)
    );
    
    // LCD消息控制模块
    lcd_messages lcd_ctrl (
        .iCLK(clk_25MHz),
        .iRST_N(!SW[0]),
        .lcd_state(lcd_state),
        .game_timer(game_timer),
        .LCD_DATA(LCD_DATA),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS)
    );
    
    // 七段数码管显示模块
    seg7_display score_display (
        .score(score),
        .hex1(HEX1),
        .hex0(HEX0)
    );

    // LCD 电源和背光控制
    assign LCD_ON = 1'b1;    // LCD 始终开启
    assign LCD_BLON = 1'b1;  // 背光始终开启
    
    // VGA同步信号
    assign VGA_CLK = clk_25MHz;
    assign VGA_BLANK_N = video_on;
    assign VGA_SYNC_N = 1'b0;
    
    // GPIO引脚
    assign GPIO[0] = 1'b1;           // VCC
    assign GPIO[1] = 1'b0;           // GND
    assign GPIO[2] = buzzer_signal;  // 触发信号
    assign GPIO[35:3] = 33'bz;
    
    // LED显示
    assign LEDG = {8'b0, buzzer_signal};

endmodule