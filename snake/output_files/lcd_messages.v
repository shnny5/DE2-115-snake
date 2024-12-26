module lcd_messages(
// Host Side
    input iCLK,
    input iRST_N,
    // Game state inputs
    input [1:0] lcd_state,    // 00: game start, 01: game over
    input [31:0] game_timer,  // Game timing counter
// LCD Side
    output [7:0]  LCD_DATA,
    output LCD_RW,
    output LCD_EN,
    output LCD_RS
);

//  Internal Wires/Registers
reg  [5:0]   LUT_INDEX;
reg  [8:0]   LUT_DATA;
reg  [5:0]   mLCD_ST;
reg  [17:0]  mDLY;
reg          mLCD_Start;
reg  [7:0]   mLCD_DATA;
reg          mLCD_RS;
wire         mLCD_Done;

parameter    LCD_INTIAL  =   0;
parameter    LCD_LINE1   =   5;
parameter    LCD_CH_LINE =   LCD_LINE1+16;
parameter    LCD_LINE2   =   LCD_LINE1+16+1;
parameter    LUT_SIZE    =   LCD_LINE1+32+1;

// Time conversion parameters
parameter    CLK_FREQ    =   25000000;  // 25MHz clock

reg [31:0] seconds;
reg [31:0] minutes;

initial begin
    refresh = 1;
end

// Convert game_timer to minutes and seconds
always @(posedge iCLK) begin
    seconds = (game_timer / CLK_FREQ) % 60;
    minutes = (game_timer / CLK_FREQ) / 60;
end

always@(posedge iCLK or negedge iRST_N) begin
    if(!iRST_N) begin
        LUT_INDEX   <= 0;
        mLCD_ST     <= 0;
        mDLY        <= 0;
        mLCD_Start  <= 0;
        mLCD_DATA   <= 0;
        mLCD_RS     <= 0;
    end
    else begin
        if(LUT_INDEX<LUT_SIZE) begin
            case(mLCD_ST)
            0:  begin
                    mLCD_DATA   <= LUT_DATA[7:0];
                    mLCD_RS     <= LUT_DATA[8];
                    mLCD_Start  <= 1;
                    mLCD_ST     <= 1;
                end
            1:  begin
                    if(mLCD_Done) begin
                        mLCD_Start  <= 0;
                        mLCD_ST     <= 2;
                    end
                end
            2:  begin
                    if(mDLY<18'h3FFFE)
                    mDLY    <= mDLY + 1'b1;
                    else begin
                        mDLY    <= 0;
                        mLCD_ST <= 3;
                    end
                end
            3:  begin
                    LUT_INDEX   <= LUT_INDEX + 1'b1;
                    mLCD_ST     <= 0;
                end
            endcase
        end
        else if(refresh == 1) begin
            LUT_INDEX <= 0;
            case(lcd_state)
                2'b00: begin // Game Start
                    // GAME START
                    line1_mess[0] <= 9'h120;  
                    line1_mess[1] <= 9'h147;  // G
                    line1_mess[2] <= 9'h141;  // A
                    line1_mess[3] <= 9'h14D;  // M
                    line1_mess[4] <= 9'h145;  // E
                    line1_mess[5] <= 9'h120;  // Space
                    line1_mess[6] <= 9'h153;  // S
                    line1_mess[7] <= 9'h154;  // T
                    line1_mess[8] <= 9'h141;  // A
                    line1_mess[9] <= 9'h152;  // R
                    line1_mess[10] <= 9'h154; // T
                    line1_mess[11] <= 9'h120; // Space
                    line1_mess[12] <= 9'h120; // Space
                    line1_mess[13] <= 9'h120; // Space
                    line1_mess[14] <= 9'h120; // Space
                    line1_mess[15] <= 9'h120; // Space

                    // Second line: "TIME: MM:SS"
                    line2_mess[0] <= 9'h154;  // T
                    line2_mess[1] <= 9'h149;  // I
                    line2_mess[2] <= 9'h14D;  // M
                    line2_mess[3] <= 9'h145;  // E
                    line2_mess[4] <= 9'h13A;  // :
                    line2_mess[5] <= 9'h120;  // Space
                    // Minutes tens 
                    line2_mess[6] <= 9'h130 + (minutes / 10);
                    // Minutes ones 
                    line2_mess[7] <= 9'h130 + (minutes % 10);
                    line2_mess[8] <= 9'h13A;  // :
                    // Seconds tens 
                    line2_mess[9] <= 9'h130 + (seconds / 10);
                    // Seconds ones
                    line2_mess[10] <= 9'h130 + (seconds % 10);
                    line2_mess[11] <= 9'h120; // Space
                    line2_mess[12] <= 9'h120; // Space
                    line2_mess[13] <= 9'h120; // Space
                    line2_mess[14] <= 9'h120; // Space
                    line2_mess[15] <= 9'h120; // Space
                end

                2'b01: begin // Game Over
                    // First line: "GAME OVER"
                    line1_mess[0] <= 9'h120;  
                    line1_mess[1] <= 9'h120;   
                    line1_mess[2] <= 9'h147;  // G
                    line1_mess[3] <= 9'h141;  // A
                    line1_mess[4] <= 9'h14D;  // M
                    line1_mess[5] <= 9'h145;  // E
                    line1_mess[6] <= 9'h120;  // Space
                    line1_mess[7] <= 9'h14F;  // O
                    line1_mess[8] <= 9'h156;  // V
                    line1_mess[9] <= 9'h145;  // E
                    line1_mess[10] <= 9'h152; // R
                    line1_mess[11] <= 9'h120; // Space
                    line1_mess[12] <= 9'h120; // Space
                    line1_mess[13] <= 9'h120; // Space
                    line1_mess[14] <= 9'h120; // Space
                    line1_mess[15] <= 9'h120; // Space

                    // Second line: Clear
                    for(i = 0; i < 16; i = i + 1) begin
                        line2_mess[i] <= 9'h120; // Space
                    end
                end
            endcase
        end
    end
end

reg [31:0] counter;
reg refresh;
reg [5:0] i;

always@(posedge iCLK) begin: increment_counter
    if(counter == 27'h17D7840) begin  // 1 秒刷新
        refresh <= 1;
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
        refresh <= 0;
    end
end

/** Message Arrays **/
reg [9:0] line1_mess [15:0];
reg [9:0] line2_mess [15:0];

always@(posedge iCLK) begin
    case(LUT_INDEX)
    //  Initial
    LCD_INTIAL+0:  LUT_DATA    <=  9'h038;
    LCD_INTIAL+1:  LUT_DATA    <=  9'h00C;
    LCD_INTIAL+2:  LUT_DATA    <=  9'h001;
    LCD_INTIAL+3:  LUT_DATA    <=  9'h006;
    LCD_INTIAL+4:  LUT_DATA    <=  9'h080;
    //  Line 1
    LCD_LINE1+0:   LUT_DATA    <=  line1_mess[0];
    LCD_LINE1+1:   LUT_DATA    <=  line1_mess[1];
    LCD_LINE1+2:   LUT_DATA    <=  line1_mess[2];
    LCD_LINE1+3:   LUT_DATA    <=  line1_mess[3];
    LCD_LINE1+4:   LUT_DATA    <=  line1_mess[4];
    LCD_LINE1+5:   LUT_DATA    <=  line1_mess[5];
    LCD_LINE1+6:   LUT_DATA    <=  line1_mess[6];
    LCD_LINE1+7:   LUT_DATA    <=  line1_mess[7];
    LCD_LINE1+8:   LUT_DATA    <=  line1_mess[8];
    LCD_LINE1+9:   LUT_DATA    <=  line1_mess[9];
    LCD_LINE1+10:  LUT_DATA    <=  line1_mess[10];
    LCD_LINE1+11:  LUT_DATA    <=  line1_mess[11];
    LCD_LINE1+12:  LUT_DATA    <=  line1_mess[12];
    LCD_LINE1+13:  LUT_DATA    <=  line1_mess[13];
    LCD_LINE1+14:  LUT_DATA    <=  line1_mess[14];
    LCD_LINE1+15:  LUT_DATA    <=  line1_mess[15];
    //  Change Line
    LCD_CH_LINE:   LUT_DATA    <=  9'h0C0;
    //  Line 2
    LCD_LINE2+0:   LUT_DATA    <=  line2_mess[0];
    LCD_LINE2+1:   LUT_DATA    <=  line2_mess[1];
    LCD_LINE2+2:   LUT_DATA    <=  line2_mess[2];
    LCD_LINE2+3:   LUT_DATA    <=  line2_mess[3];
    LCD_LINE2+4:   LUT_DATA    <=  line2_mess[4];
    LCD_LINE2+5:   LUT_DATA    <=  line2_mess[5];
    LCD_LINE2+6:   LUT_DATA    <=  line2_mess[6];
    LCD_LINE2+7:   LUT_DATA    <=  line2_mess[7];
    LCD_LINE2+8:   LUT_DATA    <=  line2_mess[8];
    LCD_LINE2+9:   LUT_DATA    <=  line2_mess[9];
    LCD_LINE2+10:  LUT_DATA    <=  line2_mess[10];
    LCD_LINE2+11:  LUT_DATA    <=  line2_mess[11];
    LCD_LINE2+12:  LUT_DATA    <=  line2_mess[12];
    LCD_LINE2+13:  LUT_DATA    <=  line2_mess[13];
    LCD_LINE2+14:  LUT_DATA    <=  line2_mess[14];
    LCD_LINE2+15:  LUT_DATA    <=  line2_mess[15];
    default:       LUT_DATA    <=  9'dx;
    endcase
end

lcd_controller u0(
    
    .iDATA(mLCD_DATA),
    .iRS(mLCD_RS),
    .iStart(mLCD_Start),
    .oDone(mLCD_Done),
    .iCLK(iCLK),
    .iRST_N(iRST_N),
    
    .LCD_DATA(LCD_DATA),
    .LCD_RW(LCD_RW),
    .LCD_EN(LCD_EN),
    .LCD_RS(LCD_RS)
);

endmodule