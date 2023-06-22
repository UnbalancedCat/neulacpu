module mul_div_top(
    input         clk,
    input         reset,
    input  [ 5:0] stall,
    output        stallreq,

    input  [ 3:0] mul_div_op,
    input         mul_div_sign,

    input  [31:0] a,
    input  [31:0] b,

    output [63:0] mul_div_result
);
    wire        stallreq_for_mul;
    wire        stallreq_for_div;
    wire        sign_flag;
    wire [31:0] src_a;
    wire [31:0] src_b; 
    wire [31:0] result_h; 
    wire [31:0] result_l; 
    wire [31:0] quotient; 
    wire [31:0] remainder;
    
    wire mul_en;
    wire div_en;

    wire [31:0] a_locked;
    wire [31:0] b_locked;
    wire        mul_en_locked;
    wire        div_en_locked;

    assign mul_en = mul_div_op[0] | mul_div_op[1];
    assign div_en = mul_div_op[2] | mul_div_op[3];

    assign sign_flag = a[31] ^ b[31];
    assign src_a = (mul_div_sign || a[31]) ? ({1'b0, ~a[30:0] + 1'b0}) : a;
    assign src_b = (mul_div_sign || b[31]) ? ({1'b0, ~b[30:0] + 1'b0}) : b;

    mul_div_lock u_mul_div_lock(
    .clk              (clk              ),
    .reset            (reset            ),
    .stall            (stall            ),
    .a                (src_a            ),
    .b                (src_b            ),
    .mul_en           (mul_en           ),
    .div_en           (div_en           ),
    .stallreq_for_mul (stallreq_for_mul ),
    .stallreq_for_div (stallreq_for_div ),
    .a_locked         (a_locked         ),
    .b_locked         (b_locked         ),
    .mul_en_locked    (mul_en_locked    ),
    .div_en_locked    (div_en_locked    )
    );

    mul u_mul(
        .clk       (clk             ),
        .reset     (reset           ),
        .stallreq  (stallreq_for_mul),
        .in_valid  (mul_en_locked   ),
        .out_valid (),
        .a         (a_locked        ),
        .b         (b_locked        ),
        .result_h  (result_h        ),
        .result_l  (result_l        )
    );

    div u_div(
        .clk       (clk             ),
        .reset     (reset           ),
        .stallreq  (stallreq_for_div),
        .in_valid  (div_en_locked   ),
        .out_valid (),
        .a         (a_locked        ),
        .b         (b_locked        ),
        .quotient  (quotient        ),
        .remainder (remainder       )
    );

    assign stallreq = stallreq_for_mul | stallreq_for_div;
    assign mul_div_result = mul_div_op[0] ? result_l  :
                            mul_div_op[1] ? result_h  :
                            mul_div_op[2] ? quotient  :
                            mul_div_op[3] ? remainder :
                                            32'b0;
    
endmodule