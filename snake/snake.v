// 首先创建单独的文件：snake_game_top.v
module snake (
    input CLOCK_50,          // 50MHz 时钟输入
    input [3:0] KEY,         // 按键输入，用于控制蛇的移动
    input reset,             // 复位信号
    // VGA接口
    output [7:0] VGA_R,     // 红色分量
    output [7:0] VGA_G,     // 绿色分量
    output [7:0] VGA_B,     // 蓝色分量
    output VGA_HS,          // 行同步信号
    output VGA_VS,          // 场同步信号
    output VGA_BLANK_N,     // 消隐信号
    output VGA_SYNC_N,      // 同步信号
    output VGA_CLK         // VGA时钟
);

    // 内部信号定义
    wire clk_25MHz;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire [23:0] rgb_out;
    wire valid_display;
    wire snake_head;
    wire snake_body;
    wire apple;
    wire game_over;

    // 时钟分频模块例化
    clock_divider clk_div (
        .clk_50MHz(CLOCK_50),
        .reset(reset),
        .clk_25MHz(clk_25MHz)
    );

    // VGA控制器例化
    vga_controller vga_ctrl (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .valid_display(valid_display),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // 游戏逻辑控制模块例化
    game_controller game_ctrl (
        .clk_25MHz(clk_25MHz),
        .reset(reset),
        .KEY(KEY),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .snake_head(snake_head),
        .snake_body(snake_body),
        .apple(apple),
        .game_over(game_over)
    );

    // 显示控制模块例化
    display_controller disp_ctrl (
        .valid_display(valid_display),
        .snake_head(snake_head),
        .snake_body(snake_body),
        .apple(apple),
        .game_over(game_over),
        .rgb_out({VGA_R, VGA_G, VGA_B})
    );

    // VGA其他信号赋值
    assign VGA_BLANK_N = 1'b1;  // 始终启用显示
    assign VGA_SYNC_N = 1'b0;   // 不使用复合同步
    assign VGA_CLK = ~clk_25MHz; // 反相时钟以确保正确的像素同步

endmodule

// 第二个文件：clock_divider.v
module clock_divider (
    input clk_50MHz,
    input reset,
    output reg clk_25MHz
);
    
    reg clk_div;
    
    always @(posedge clk_50MHz or posedge reset) begin
        if (reset) begin
            clk_div <= 1'b0;
            clk_25MHz <= 1'b0;
        end
        else begin
            clk_div <= ~clk_div;
            if (clk_div)
                clk_25MHz <= ~clk_25MHz;
        end
    end
    
endmodule

// 第三个文件：vga_controller.v
module vga_controller (
    input clk_25MHz,
    input reset,
    output reg hsync,
    output reg vsync,
    output reg valid_display,
    output reg [9:0] pixel_x,
    output reg [9:0] pixel_y
);

    // VGA 640x480 @ 60Hz timing parameters
    parameter H_DISPLAY = 640;  // 水平显示区域
    parameter H_FRONT = 16;     // 水平前沿
    parameter H_SYNC = 96;      // 水平同步
    parameter H_BACK = 48;      // 水平后沿
    parameter H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;  // 总水平像素
    
    parameter V_DISPLAY = 480;  // 垂直显示区域
    parameter V_FRONT = 10;     // 垂直前沿
    parameter V_SYNC = 2;       // 垂直同步
    parameter V_BACK = 33;      // 垂直后沿
    parameter V_TOTAL = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;  // 总垂直行数

    // 计数器
    reg [9:0] h_count;
    reg [9:0] v_count;

    // 水平计数
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset)
            h_count <= 10'b0;
        else if (h_count == (H_DISPLAY + H_FRONT + H_SYNC + H_BACK - 1))
            h_count <= 10'b0;
        else
            h_count <= h_count + 1'b1;
    end

    // 垂直计数
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset)
            v_count <= 10'b0;
        else if (h_count == (H_DISPLAY + H_FRONT + H_SYNC + H_BACK - 1)) begin
            if (v_count == (V_DISPLAY + V_FRONT + V_SYNC + V_BACK - 1))
                v_count <= 10'b0;
            else
                v_count <= v_count + 1'b1;
        end
    end

    // 同步信号生成
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end
        else begin
            // 同步信号为负极性
            hsync <= ~((h_count >= (H_DISPLAY + H_FRONT)) && 
                      (h_count < (H_DISPLAY + H_FRONT + H_SYNC)));
            vsync <= ~((v_count >= (V_DISPLAY + V_FRONT)) && 
                      (v_count < (V_DISPLAY + V_FRONT + V_SYNC)));
        end
    end

    // 有效显示区域判断
    wire h_valid, v_valid;
    assign h_valid = (h_count < H_DISPLAY);
    assign v_valid = (v_count < V_DISPLAY);
    
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset)
            valid_display <= 1'b0;
        else
            valid_display <= h_valid && v_valid;
    end

    // 像素坐标输出
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            pixel_x <= 10'b0;
            pixel_y <= 10'b0;
        end
        else begin
            pixel_x <= h_count;
            pixel_y <= v_count;
        end
    end

endmodule

// 第四个文件：game_controller.v
module game_controller (
    input clk_25MHz,
    input reset,
    input [3:0] KEY,          // KEY[0]: up, KEY[1]: down, KEY[2]: left, KEY[3]: right
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    output snake_head,
    output snake_body,
    output apple,
    output game_over
);

    // 游戏参数定义
    parameter GRID_SIZE = 20;  // 网格大小
    parameter GAME_SPEED = 5000000;  // 游戏速度（时钟周期数）
    parameter MAX_LENGTH = 32;  // 蛇的最大长度，减小以避免综合问题
    parameter INITIAL_LENGTH = 1;  // 初始长度
    parameter MAX_COUNT = 31;  // 循环最大计数值

    // 方向定义
    parameter UP = 2'b00;
    parameter DOWN = 2'b01;
    parameter LEFT = 2'b10;
    parameter RIGHT = 2'b11;

    // 内部寄存器
    reg [9:0] snake_x [0:MAX_LENGTH-1];  // 蛇身体x坐标
    reg [9:0] snake_y [0:MAX_LENGTH-1];  // 蛇身体y坐标
    reg [6:0] snake_length;              // 蛇的当前长度
    reg [1:0] direction;                 // 当前移动方向
    reg [9:0] apple_x;                   // 苹果x坐标
    reg [9:0] apple_y;                   // 苹果y坐标
    reg game_over_reg;                   // 游戏结束标志
    reg [22:0] move_counter;             // 移动计数器
    
    // 用于循环的变量
    reg [6:0] i;

    // 游戏状态控制
    always @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            // 初始化蛇的位置
            snake_x[0] <= 10'd320;
            snake_y[0] <= 10'd240;
            snake_length <= 7'd1;
            direction <= RIGHT;
            game_over_reg <= 1'b0;
            move_counter <= 23'd0;
            apple_x <= 10'd400;
            apple_y <= 10'd300;
            i <= 0;
        end
        else begin
            if (!game_over_reg) begin
                // 处理按键输入
                if (!KEY[0] && direction != DOWN) direction <= UP;
                else if (!KEY[1] && direction != UP) direction <= DOWN;
                else if (!KEY[2] && direction != RIGHT) direction <= LEFT;
                else if (!KEY[3] && direction != LEFT) direction <= RIGHT;

                // 移动蛇
                if (move_counter == GAME_SPEED) begin
                    move_counter <= 23'd0;
                    
                    // 更新蛇身体位置
                    if (i < snake_length && i < MAX_COUNT) begin
                        snake_x[snake_length-i] <= snake_x[snake_length-i-1];
                        snake_y[snake_length-i] <= snake_y[snake_length-i-1];
                        i <= i + 1'b1;
                    end
                    else begin
                        i <= 0;
                        // 更新蛇头位置
                        case (direction)
                            UP: snake_y[0] <= snake_y[0] - GRID_SIZE;
                            DOWN: snake_y[0] <= snake_y[0] + GRID_SIZE;
                            LEFT: snake_x[0] <= snake_x[0] - GRID_SIZE;
                            RIGHT: snake_x[0] <= snake_x[0] + GRID_SIZE;
                        endcase

                        // 检测碰撞
                        if (snake_x[0] < 10'd0 || snake_x[0] >= 10'd640 ||
                            snake_y[0] < 10'd0 || snake_y[0] >= 10'd480) begin
                            game_over_reg <= 1'b1;
                        end

                        // 检测是否吃到苹果
                        if (snake_x[0] == apple_x && snake_y[0] == apple_y && 
                            snake_length < MAX_LENGTH-1) begin
                            snake_length <= snake_length + 1'b1;
                            apple_x <= (apple_x + 10'd100) % 10'd620;
                            apple_y <= (apple_y + 10'd80) % 10'd460;
                        end
                    end
                end
                else begin
                    move_counter <= move_counter + 1'b1;
                end
            end
        end
    end

    // 蛇身体检测逻辑
    reg body_detected;
    reg [5:0] j;  // 循环变量，位宽减小以匹配MAX_LENGTH

    always @* begin
        body_detected = 0;
        j = 1;
        while (j < snake_length && j < MAX_LENGTH) begin
            if (pixel_x >= snake_x[j] && pixel_x < snake_x[j] + GRID_SIZE &&
                pixel_y >= snake_y[j] && pixel_y < snake_y[j] + GRID_SIZE)
                body_detected = 1;
            j = j + 1;
        end
    end

    // 输出信号生成
    assign snake_head = (pixel_x >= snake_x[0] && pixel_x < snake_x[0] + GRID_SIZE &&
                        pixel_y >= snake_y[0] && pixel_y < snake_y[0] + GRID_SIZE);
    assign snake_body = body_detected;
    assign apple = (pixel_x >= apple_x && pixel_x < apple_x + GRID_SIZE &&
                   pixel_y >= apple_y && pixel_y < apple_y + GRID_SIZE);
    assign game_over = game_over_reg;

endmodule

// 第五个文件：display_controller.v
module display_controller (
    input valid_display,
    input snake_head,
    input snake_body,
    input apple,
    input game_over,
    output reg [23:0] rgb_out
);

    // 颜色定义
    parameter COLOR_BLACK = 24'h000000;
    parameter COLOR_GREEN = 24'h00FF00;
    parameter COLOR_RED = 24'hFF0000;
    parameter COLOR_BLUE = 24'h0000FF;
    parameter COLOR_WHITE = 24'hFFFFFF;

    // 显示控制逻辑
    always @* begin
        if (!valid_display)
            rgb_out = COLOR_BLACK;
        else if (game_over)
            rgb_out = COLOR_RED;
        else if (snake_head)
            rgb_out = COLOR_BLUE;
        else if (snake_body)
            rgb_out = COLOR_GREEN;
        else if (apple)
            rgb_out = COLOR_RED;
        else
            rgb_out = COLOR_BLACK;
    end

endmodule