module vga_controller(
    input clk_25MHz,
    input reset_n,
    output hsync,
    output vsync,
    output video_on,
    output [9:0] pixel_x,
    output [9:0] pixel_y,
    output p_tick
);
    // VGA 680x480 参数
    parameter HD = 680;  // 水平
    parameter HF = 16;   // 前肩
    parameter HB = 48;   // 后肩
    parameter HR = 96;   // 同步脉冲
    parameter VD = 480;  // 垂直
    parameter VF = 10;   // 前肩
    parameter VB = 33;   // 后肩
    parameter VR = 2;    // 同步脉冲
    
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // 水平计数器
    always @(posedge clk_25MHz or negedge reset_n)
    begin
        if(!reset_n)
            h_count <= 10'b0;
        else if(h_count == (HD + HF + HB + HR - 1))
            h_count <= 10'b0;
        else
            h_count <= h_count + 1'b1;
    end
    
    // 垂直计数器
    always @(posedge clk_25MHz or negedge reset_n)
    begin
        if(!reset_n)
            v_count <= 10'b0;
        else if(h_count == (HD + HF + HB + HR - 1))
            if(v_count == (VD + VF + VB + VR - 1))
                v_count <= 10'b0;
            else
                v_count <= v_count + 1'b1;
    end
    
    // 同步信号
    assign hsync = (h_count >= (HD + HF) && h_count <= (HD + HF + HR - 1));
    assign vsync = (v_count >= (VD + VF) && v_count <= (VD + VF + VR - 1));
    assign video_on = (h_count < HD) && (v_count < VD);
    assign pixel_x = h_count;
    assign pixel_y = v_count;
    
    // 帧率
    assign p_tick = (h_count == 0 && v_count == 0);
    
endmodule