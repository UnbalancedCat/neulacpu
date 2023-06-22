module regfile(
    input         clk,
    input         reset,
    // READ PORT 1
    input  [ 4:0] raddr1,
    output [31:0] rdata1,
    // READ PORT 2
    input  [ 4:0] raddr2,
    output [31:0] rdata2,
    // WRITE PORT
    input         we,       //write enable, HIGH valid
    input  [ 4:0] waddr,
    input  [31:0] wdata
);
    reg [31:0] rf[31:0];

    //WRITE
    always @(posedge clk) begin
        if (reset) begin
            rf[ 0] <= 32'b0;
            rf[ 1] <= 32'b0;
            rf[ 2] <= 32'b0;
            rf[ 3] <= 32'b0;
            rf[ 4] <= 32'b0;
            rf[ 5] <= 32'b0;
            rf[ 6] <= 32'b0;
            rf[ 7] <= 32'b0;
            rf[ 8] <= 32'b0;
            rf[ 9] <= 32'b0;
            rf[10] <= 32'b0;
            rf[11] <= 32'b0;
            rf[12] <= 32'b0;
            rf[13] <= 32'b0;
            rf[14] <= 32'b0;
            rf[15] <= 32'b0;
            rf[16] <= 32'b0;
            rf[17] <= 32'b0;
            rf[18] <= 32'b0;
            rf[19] <= 32'b0;
            rf[20] <= 32'b0;
            rf[21] <= 32'b0;
            rf[22] <= 32'b0;
            rf[23] <= 32'b0;
            rf[24] <= 32'b0;
            rf[25] <= 32'b0;
            rf[26] <= 32'b0;
            rf[27] <= 32'b0;
            rf[28] <= 32'b0;
            rf[29] <= 32'b0;
            rf[30] <= 32'b0;
            rf[31] <= 32'b0;
        end
        else if (we) begin
            rf[waddr]<= wdata;
        end
    end

    //READ OUT 1
    assign rdata1 = (raddr1==5'b0 ) ? 32'b0 : 
                    (raddr1==waddr) ? wdata :
                                      rf[raddr1];

    //READ OUT 2
    assign rdata2 = (raddr2==5'b0 ) ? 32'b0 : 
                    (raddr2==waddr) ? wdata :
                                      rf[raddr2];

endmodule