module reset_delay(
    input iCLK,
    output reg oRESET
);


reg [25:0] Cont;

always @(posedge iCLK) begin
    if(Cont != 26'h2FAF080) begin  
        Cont <= Cont + 1'b1;
        oRESET <= 1'b0;
    end
    else begin
        oRESET <= 1'b1;
    end
end

endmodule