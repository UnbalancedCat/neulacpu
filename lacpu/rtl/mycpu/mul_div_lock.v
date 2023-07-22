module mul_div_lock (
    input         clk,
    input         reset,
    input  [ 5:0] stall,
    input  [31:0] a,
    input  [31:0] b,
    input         mul_en, 
    input         div_en,
    input         stallreq_for_mul, 
    input         stallreq_for_div,
    
    output [31:0] a_locked,
    output [31:0] b_locked,
    output        mul_en_locked,
    output        div_en_locked
);
    reg        first_enable;
    reg        mul_en_musk;
    reg        div_en_musk;
    reg [31:0] a_buffer;
    reg [31:0] b_buffer;

    wire stallreq = stallreq_for_mul | stallreq_for_div;

    assign mul_en_locked = mul_en & mul_en_musk;
    assign div_en_locked = div_en & div_en_musk;
    
    assign a_locked = first_enable ? a : a_buffer;
    assign b_locked = first_enable ? b : b_buffer;

    always @ (posedge clk) begin
        if (reset) begin
            a_buffer <= 0;
            b_buffer <= 0;
            mul_en_musk <= 1;
            div_en_musk <= 1;

            first_enable <= 1;
        end
        else if (mul_en & first_enable) begin
            a_buffer <= a;
            b_buffer <= b;
            mul_en_musk <= 0;
            div_en_musk <= 1;

            first_enable <= 0;
        end 
        else if (div_en & first_enable) begin
            a_buffer <= a;
            b_buffer <= b;
            mul_en_musk <= 1;
            div_en_musk <= 0;

            first_enable <= 0;
        end
        else if (!stallreq & (mul_en|div_en) & !first_enable & !stall[2]) begin
            a_buffer <= 0;
            b_buffer <= 0;
            mul_en_musk <= 1;
            div_en_musk <= 1;

            first_enable <= 1;
        end

    end
endmodule