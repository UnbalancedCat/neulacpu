module mul(
    input         clk,
    input         reset,
    output        stallreq,
    input         in_valid,
    output        out_valid,

    input  [31:0] a,
    input  [31:0] b,
    
    output reg [31:0] result_h,
    output reg [31:0] result_l
);
    reg  [ 5:0] cnt;
    wire [31:0] add_result;
    wire        carry;

    wire [63:0] mul_result;

    always @ (posedge clk) begin
        if (reset) begin
            cnt <= 0;
        end
        else if (cnt != 0) begin
            cnt <= cnt - 1;
        end
        else if (in_valid) begin
            cnt <= 1;//32;
        end
    end

    assign mul_result = a * b;

    always @ (posedge clk) begin
        if (reset) begin
            result_h <= 0;
            result_l <= 0;
        end 
        else if (cnt != 0) begin
            //{result_h, result_l} <= {carry, add_result, result_l[31:1]};
            result_h <= mul_result[63:32];
            result_l <= mul_result[31: 0];
        end
        else if (in_valid) begin
            result_h <= 0;
            result_l <= 0;//b;
        end
    end 

    assign out_valid = (cnt==0);
    assign stallreq = in_valid | (~(cnt==0));
endmodule