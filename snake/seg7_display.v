module seg7_display(
    input [6:0] score,           
    output reg [6:0] hex1,       
    output reg [6:0] hex0        
);

    
    wire [3:0] tens;             
    wire [3:0] ones;            
    
   
    assign tens = score / 10;
    assign ones = score % 10;
    
    
    function [6:0] encode_digit;
        input [3:0] digit;
        begin
            case(digit)
                4'h0: encode_digit = 7'b1000000;  // 0
                4'h1: encode_digit = 7'b1111001;  // 1
                4'h2: encode_digit = 7'b0100100;  // 2
                4'h3: encode_digit = 7'b0110000;  // 3
                4'h4: encode_digit = 7'b0011001;  // 4
                4'h5: encode_digit = 7'b0010010;  // 5
                4'h6: encode_digit = 7'b0000010;  // 6
                4'h7: encode_digit = 7'b1111000;  // 7
                4'h8: encode_digit = 7'b0000000;  // 8
                4'h9: encode_digit = 7'b0010000;  // 9
                default: encode_digit = 7'b1111111; 
            endcase
        end
    endfunction
    
    // 更新显示
    always @(*) begin
        hex1 = encode_digit(tens);
        hex0 = encode_digit(ones);
    end

endmodule