module text_display(
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    output reg [23:0] rgb_out
);
    // 文字显示参数
    parameter CHAR_WIDTH = 8;    // 字符宽度
    parameter CHAR_HEIGHT = 16;  // 每个字符高度
    parameter TEXT_X = 280;      // 文字起始X坐标
    parameter TEXT_Y = 220;      // 文字起始Y坐标
    parameter BLACK = 24'h000000;
    parameter WHITE = 24'hFFFFFF;

    // ROM存储字符位图数据
    reg [7:0] char_L [0:15];
    reg [7:0] char_O [0:15];
    reg [7:0] char_A [0:15];
    reg [7:0] char_D [0:15];
    reg [7:0] char_G [0:15];
    reg [7:0] char_M [0:15];
    reg [7:0] char_E [0:15];
    reg [7:0] char_space [0:15];
    
    // 用于计算当前字符位置
    wire [3:0] char_index;
    wire [3:0] char_row;
    wire [2:0] char_col;
    reg [7:0] current_char [0:15];
    
    // 计算相对位置
    assign char_index = (pixel_x - TEXT_X) / CHAR_WIDTH;
    assign char_row = pixel_y - TEXT_Y;
    assign char_col = (pixel_x - TEXT_X) % CHAR_WIDTH;

    // 初始化字符数据
    initial begin
        // 字符 L
        char_L[0]  = 8'b10000000; 
        char_L[1]  = 8'b10000000; 
        char_L[2]  = 8'b10000000; 
        char_L[3]  = 8'b10000000; 
        char_L[4]  = 8'b10000000; 
        char_L[5]  = 8'b10000000; 
        char_L[6]  = 8'b10000000; 
        char_L[7]  = 8'b10000000; 
        char_L[8]  = 8'b10000000; 
        char_L[9]  = 8'b10000000; 
        char_L[10] = 8'b10000000; 
        char_L[11] = 8'b10000000; 
        char_L[12] = 8'b10000000; 
        char_L[13] = 8'b10000000; 
        char_L[14] = 8'b10000000; 
        char_L[15] = 8'b11111111; 
        
        // 字符 O
        char_O[0]  = 8'b01111100;
        char_O[1]  = 8'b10000010;
        char_O[2]  = 8'b10000010;
        char_O[3]  = 8'b10000010;
        char_O[4]  = 8'b10000010;
        char_O[5]  = 8'b10000010;
        char_O[6]  = 8'b10000010;
        char_O[7]  = 8'b10000010;
        char_O[8]  = 8'b10000010;
        char_O[9]  = 8'b10000010;
        char_O[10] = 8'b10000010;
        char_O[11] = 8'b10000010;
        char_O[12] = 8'b10000010;
        char_O[13] = 8'b10000010;
        char_O[14] = 8'b01111100;
        char_O[15] = 8'b00000000;

        // 字符 A
        char_A[0]  = 8'b00111000;
        char_A[1]  = 8'b01000100;
        char_A[2]  = 8'b10000010;
        char_A[3]  = 8'b10000010;
        char_A[4]  = 8'b10000010;
        char_A[5]  = 8'b11111110;
        char_A[6]  = 8'b10000010;
        char_A[7]  = 8'b10000010;
        char_A[8]  = 8'b10000010;
        char_A[9]  = 8'b10000010;
        char_A[10] = 8'b10000010;
        char_A[11] = 8'b10000010;
        char_A[12] = 8'b10000010;
        char_A[13] = 8'b10000010;
        char_A[14] = 8'b00000000;
        char_A[15] = 8'b00000000;

        // 字符 D
        char_D[0]  = 8'b11111100;
        char_D[1]  = 8'b10000010;
        char_D[2]  = 8'b10000010;
        char_D[3]  = 8'b10000010;
        char_D[4]  = 8'b10000010;
        char_D[5]  = 8'b10000010;
        char_D[6]  = 8'b10000010;
        char_D[7]  = 8'b10000010;
        char_D[8]  = 8'b10000010;
        char_D[9]  = 8'b10000010;
        char_D[10] = 8'b10000010;
        char_D[11] = 8'b11111100;
        char_D[12] = 8'b00000000;
        char_D[13] = 8'b00000000;
        char_D[14] = 8'b00000000;
        char_D[15] = 8'b00000000;

        // 字符 G
        char_G[0]  = 8'b01111100;
        char_G[1]  = 8'b10000010;
        char_G[2]  = 8'b10000000;
        char_G[3]  = 8'b10000000;
        char_G[4]  = 8'b10000000;
        char_G[5]  = 8'b10011110;
        char_G[6]  = 8'b10000010;
        char_G[7]  = 8'b10000010;
        char_G[8]  = 8'b10000010;
        char_G[9]  = 8'b10000010;
        char_G[10] = 8'b10000010;
        char_G[11] = 8'b01111100;
        char_G[12] = 8'b00000000;
        char_G[13] = 8'b00000000;
        char_G[14] = 8'b00000000;
        char_G[15] = 8'b00000000;

        // 字符 M
        char_M[0]  = 8'b10000010;
        char_M[1]  = 8'b11000110;
        char_M[2]  = 8'b10101010;
        char_M[3]  = 8'b10010010;
        char_M[4]  = 8'b10000010;
        char_M[5]  = 8'b10000010;
        char_M[6]  = 8'b10000010;
        char_M[7]  = 8'b10000010;
        char_M[8]  = 8'b10000010;
        char_M[9]  = 8'b10000010;
        char_M[10] = 8'b10000010;
        char_M[11] = 8'b10000010;
        char_M[12] = 8'b00000000;
        char_M[13] = 8'b00000000;
        char_M[14] = 8'b00000000;
        char_M[15] = 8'b00000000;

        // 空格字符
        char_space[0] = 8'b00000000;
    end
endmodule
