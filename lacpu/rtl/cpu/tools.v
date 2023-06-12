`default_nettype wire
module decoder_5_32(
    input  [ 4:0] in,
    output [31:0] out
);

    genvar i;
    generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
        assign out[i] = (in == i);
    end endgenerate

    endmodule


module decoder_3_8(
    input  [2:0] in,
    output [7:0] out
);

    genvar i;
    generate for (i=0; i<8; i=i+1) begin : gen_for_dec_3_8
        assign out[i] = (in == i);
    end endgenerate

endmodule