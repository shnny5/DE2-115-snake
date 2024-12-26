// LFSR随机数生成器
module lfsr_16bit(
    input clk,
    input reset_n,
    output reg [15:0] rand_num
);
    wire feedback;
    
    // 使用多项式 x^16 + x^14 + x^13 + x^11 + 1
    assign feedback = rand_num[15] ^ rand_num[13] ^ rand_num[12] ^ rand_num[10];
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            rand_num <= 16'hABCD;  // 初始值
        else
            rand_num <= {rand_num[14:0], feedback};
    end
endmodule