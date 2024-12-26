module lcd1602(
    input clk_50M,
    input rst,
    input game_state,           // 从game_control接收游戏状态
    input [31:0] game_time,     // 从game_control接收游戏时间
    output en,
    output RS,
    output RW,
    output [7:0] data
);

wire clk_500;

clk_50M_500 u_clk50M_500(
    .clk_50M(clk_50M),
    .rst(rst),
    .clk_500(clk_500)
);
                     
lcd_show u_lcd_show(
    .clk_LCD(clk_500),
    .rst(rst),
    .game_state(game_state),
    .game_time(game_time),
    .en(en),
    .RS(RS),
    .RW(RW),
    .data(data)
);
                    
endmodule 

module lcd_show(
    input clk_LCD,
    input rst,
    input game_state,
    input [31:0] game_time,
    output en,
    output RS,
    output RW,
    output reg [7:0] data
); 
          
reg en_sel;
reg rs_reg;
reg [4:0] disp_count;
reg [4:0] write_count;
reg [2:0] num;
reg [3:0] state;

parameter clear_lcd          = 4'b1000,
          set_disp_mode     = 4'b1001,
          disp_on           = 4'b1010,
          shift_down        = 4'b1011,
          write_data_first  = 4'b1100,
          write_data_second = 4'b1101,
          idel              = 4'b1110;
          
assign RW = 1'b0;
assign en = en_sel ? clk_LCD : 1'b0;
assign RS = rs_reg;

// 寄存器保存第一行和第二行的显示内容
reg [7:0] data_first_line  [15:0];
reg [7:0] data_second_line [15:0];

// ASCII转换模块
reg [7:0] time_digits [9:0]; // 用于存储转换后的时间数字
reg [3:0] bcd_time [9:0];    // 用于BCD转换

// 生成居中显示的偏移量
parameter CENTER_OFFSET_GAME_START = 3; // "GAME START" 长度为9，居中偏移3
parameter CENTER_OFFSET_GAME_OVER = 3;  // "GAME OVER" 长度为9，居中偏移3
parameter CENTER_OFFSET_TIMING = 5;     // "TIMING: XXs" 最长11位，居中偏移5

integer j;  // 用于for循环

// BCD转换和ASCII转换
always @(posedge clk_LCD) begin
    // 将时间转换为BCD码
    bcd_time[0] = game_time % 10;
    bcd_time[1] = (game_time / 10) % 10;
    bcd_time[2] = (game_time / 100) % 10;
    
    // 转换为ASCII码
    for(j = 0; j < 10; j = j + 1) begin
        time_digits[j] = 8'h30 + bcd_time[j];
    end
end

// 更新显示内容
always @(posedge clk_LCD) begin
    if (game_state) begin
        // 游戏运行中显示 "GAME START" 和 "TIMING: XXs"
        // 第一行 - GAME START
        data_first_line[0+CENTER_OFFSET_GAME_START]  <= 8'h47; // G
        data_first_line[1+CENTER_OFFSET_GAME_START]  <= 8'h41; // A
        data_first_line[2+CENTER_OFFSET_GAME_START]  <= 8'h4D; // M
        data_first_line[3+CENTER_OFFSET_GAME_START]  <= 8'h45; // E
        data_first_line[4+CENTER_OFFSET_GAME_START]  <= 8'h20; // Space
        data_first_line[5+CENTER_OFFSET_GAME_START]  <= 8'h53; // S
        data_first_line[6+CENTER_OFFSET_GAME_START]  <= 8'h54; // T
        data_first_line[7+CENTER_OFFSET_GAME_START]  <= 8'h41; // A
        data_first_line[8+CENTER_OFFSET_GAME_START]  <= 8'h52; // R
        data_first_line[9+CENTER_OFFSET_GAME_START]  <= 8'h54; // T
        
        // 第二行 - TIMING: XXs
        data_second_line[0+CENTER_OFFSET_TIMING]  <= 8'h54; // T
        data_second_line[1+CENTER_OFFSET_TIMING]  <= 8'h49; // I
        data_second_line[2+CENTER_OFFSET_TIMING]  <= 8'h4D; // M
        data_second_line[3+CENTER_OFFSET_TIMING]  <= 8'h49; // I
        data_second_line[4+CENTER_OFFSET_TIMING]  <= 8'h4E; // N
        data_second_line[5+CENTER_OFFSET_TIMING]  <= 8'h47; // G
        data_second_line[6+CENTER_OFFSET_TIMING]  <= 8'h3A; // :
        data_second_line[7+CENTER_OFFSET_TIMING]  <= 8'h20; // Space
        data_second_line[8+CENTER_OFFSET_TIMING]  <= time_digits[1]; // 十位
        data_second_line[9+CENTER_OFFSET_TIMING]  <= time_digits[0]; // 个位
        data_second_line[10+CENTER_OFFSET_TIMING] <= 8'h73; // s
    end
    else begin
        // 游戏结束显示 "GAME OVER"
        // 第一行 - GAME OVER
        data_first_line[0+CENTER_OFFSET_GAME_OVER]  <= 8'h47; // G
        data_first_line[1+CENTER_OFFSET_GAME_OVER]  <= 8'h41; // A
        data_first_line[2+CENTER_OFFSET_GAME_OVER]  <= 8'h4D; // M
        data_first_line[3+CENTER_OFFSET_GAME_OVER]  <= 8'h45; // E
        data_first_line[4+CENTER_OFFSET_GAME_OVER]  <= 8'h20; // Space
        data_first_line[5+CENTER_OFFSET_GAME_OVER]  <= 8'h4F; // O
        data_first_line[6+CENTER_OFFSET_GAME_OVER]  <= 8'h56; // V
        data_first_line[7+CENTER_OFFSET_GAME_OVER]  <= 8'h45; // E
        data_first_line[8+CENTER_OFFSET_GAME_OVER]  <= 8'h52; // R
        
        // 第二行 - 空白
        for(j = 0; j < 16; j = j + 1) begin
            data_second_line[j] <= 8'h20; // Space
        end
    end
end

// LCD状态机
always @(posedge clk_LCD or negedge rst) begin
    if(!rst) begin
        state <= clear_lcd;
        rs_reg <= 1'b0;
        data <= 8'b0;
        en_sel <= 1'b1;
        disp_count <= 5'b0;
        write_count <= 5'b0;
    end
    else begin
        case(state)
            clear_lcd: begin 
                state <= set_disp_mode;
                data <= 8'h01;  // 清屏命令
                rs_reg <= 1'b0;
            end
            
            set_disp_mode: begin 
                state <= disp_on;
                data <= 8'h38;  // 设置显示模式
                rs_reg <= 1'b0;
            end
            
            disp_on: begin 
                state <= shift_down;
                data <= 8'h0c;  // 显示开启，光标关闭
                rs_reg <= 1'b0;
            end
            
            shift_down: begin 
                state <= write_data_first;
                data <= 8'h06;  // 设置光标移动方向
                rs_reg <= 1'b0;
            end
            
            write_data_first: begin 
                if(disp_count == 0) begin
                    data <= 8'h80;  // 设置DDRAM地址到第一行起始位置
                    rs_reg <= 1'b0;
                    disp_count <= disp_count + 1'b1;
                end
                else if(disp_count <= 16) begin
                    data <= data_first_line[disp_count-1];
                    rs_reg <= 1'b1;
                    disp_count <= disp_count + 1'b1;
                end
                else begin
                    state <= write_data_second;
                    data <= 8'hC0;  // 设置DDRAM地址到第二行起始位置
                    rs_reg <= 1'b0;
                    disp_count <= 5'b0;
                end
            end
            
            write_data_second: begin
                if(disp_count == 0) begin
                    disp_count <= disp_count + 1'b1;
                end
                else if(disp_count <= 16) begin
                    data <= data_second_line[disp_count-1];
                    rs_reg <= 1'b1;
                    disp_count <= disp_count + 1'b1;
                end
                else begin
                    state <= clear_lcd;  // 循环显示
                    disp_count <= 5'b0;
                end
            end
            
            default: state <= clear_lcd;
        endcase
    end
end

endmodule