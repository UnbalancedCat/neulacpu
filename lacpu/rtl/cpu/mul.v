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
    always @ (posedge clk) begin
        if (reset) begin
            cnt <= 0;
        end
        else if (cnt != 0) begin
            cnt <= cnt - 1;
        end
        else if (in_valid) begin
            cnt <= 32;
        end
    end

    assign {carry, add_result} = result_h + (result_l[0] ? a : 0);

    always @ (posedge clk) begin
        if (reset) begin
            result_h <= 0;
            result_l <= 0;
        end 
        else if (cnt != 0) begin
            {result_h, result_l} <= {carry, add_result, result_l[31:1]};
        end
        else if (in_valid) begin
            result_h <= 0;
            result_l <= b;
        end
    end 

    assign out_valid = (cnt==0);
    assign stallreq = in_valid | (~(cnt==0));
endmodule