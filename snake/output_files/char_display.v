module char_display (
    input [7:0] char,        // 单个字符输入，ASCII 编码
    output reg [8:0] seg_out // 输出九段译码，9'h格式
);

always @(*) begin
    case (char)
        // 数字 0-9 的九段译码
        "0": seg_out = 9'h120; 
        "1": seg_out = 9'h1F0; 
        "2": seg_out = 9'h249; 
        "3": seg_out = 9'h309; 
        "4": seg_out = 9'h1C9; 
        "5": seg_out = 9'h193; 
        "6": seg_out = 9'h092; 
        "7": seg_out = 9'h3E0; 
        "8": seg_out = 9'h010; 
        "9": seg_out = 9'h190; 

        // 大写字母 A-Z 的九段译码
        "A": seg_out = 9'h021; 
        "B": seg_out = 9'h013; 
        "C": seg_out = 9'h160; 
        "D": seg_out = 9'h048;
        "E": seg_out = 9'h183; 
        "F": seg_out = 9'h187;
        "G": seg_out = 9'h062;
        "H": seg_out = 9'h0C7;
        "I": seg_out = 9'h1F0;
        "J": seg_out = 9'h0C8;
        "K": seg_out = 9'h085;
        "L": seg_out = 9'h1E0; 
        "M": seg_out = 9'h041; 
        "N": seg_out = 9'h049; 
        "O": seg_out = 9'h120; 
        "P": seg_out = 9'h187; 
        "Q": seg_out = 9'h100; 
        "R": seg_out = 9'h105; 
        "S": seg_out = 9'h193; 
        "T": seg_out = 9'h1F0; 
        "U": seg_out = 9'h0E0; 
        "V": seg_out = 9'h0A1; 
        "W": seg_out = 9'h0C1; 
        "X": seg_out = 9'h0C7; 
        "Y": seg_out = 9'h1C8; 
        "Z": seg_out = 9'h249; 

        // 小写字母 a-z 的九段译码
        "a": seg_out = 9'h021; 
        "b": seg_out = 9'h013; 
        "c": seg_out = 9'h160; 
        "d": seg_out = 9'h048; 
        "e": seg_out = 9'h183; 
        "f": seg_out = 9'h187; 
        "g": seg_out = 9'h062; 
        "h": seg_out = 9'h0C7;
        "i": seg_out = 9'h1F0; 
        "j": seg_out = 9'h0C8; 
        "k": seg_out = 9'h085; 
        "l": seg_out = 9'h1E0; 
        "m": seg_out = 9'h041; 
        "n": seg_out = 9'h049; 
        "o": seg_out = 9'h120; 
        "p": seg_out = 9'h187; 
        "q": seg_out = 9'h100; 
        "r": seg_out = 9'h105; 
        "s": seg_out = 9'h193; 
        "t": seg_out = 9'h1F0; 
        "u": seg_out = 9'h0E0; 
        "v": seg_out = 9'h0A1; 
        "w": seg_out = 9'h0C1; 
        "x": seg_out = 9'h0C7; 
        "y": seg_out = 9'h1C8; 
        "z": seg_out = 9'h249; 

        // 默认值
        default: seg_out = 9'h1FF; 
    endcase
end

endmodule
