module clock_divider(
    input clk_50MHz,
    input reset_n,
    output reg clk_25MHz
);
    
    always @(posedge clk_50MHz or negedge reset_n)
    begin
        if(!reset_n)
            clk_25MHz <= 1'b0;
        else
            clk_25MHz <= ~clk_25MHz;
    end
    
endmodule