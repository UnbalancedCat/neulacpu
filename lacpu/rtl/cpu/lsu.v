module lsu(
    input  [ 5:0] load_op,
    input  [ 2:0] store_op,
    input  [31:0] rj_value,
    input  [31:0] rkd_value,
    input  [31:0] imm,

    output        data_sram_en,
    output        data_sram_we,
    output        data_sram_addr,
    output        data_sram_wdata
);
    wire        inst_ll_w;
    wire        inst_ld_b;
    wire        inst_ld_bu;
    wire        inst_ld_h;
    wire        inst_ld_hu;
    wire        inst_ld_w;
    wire        inst_st_b;
    wire        inst_st_h;
    wire        inst_st_w;

    wire [31:0] addr;
    wire [ 3:0] byte_sel;

    assign {inst_ld_b,
            inst_ld_h,
            inst_ld_w, 
            inst_ld_bu, 
            inst_ld_hu, 
            inst_ll_w
           } = load_op;

    assign {inst_st_b,
            inst_st_h, 
            inst_st_w
           } = store_op;

    assign addr = rj_value + imm;

    decoder_2_4 u_decoder_2_4(
        .in (addr[1:0]),
        .out(byte_sel )
    );

    assign data_sram_en    = (|store_op) | (|load_op);
    assign data_sram_we    = inst_st_b ?     byte_sel                         :
                             inst_st_h ? {{2{byte_sel[2]}}, {2{byte_sel[0]}}} :
                             inst_st_w ? { 4{byte_sel[0]}}                    :
                                           4'b0;
    assign data_sram_addr  = addr;
    assign data_sram_wdata = inst_st_b ? {4{rkd_value[ 7:0]}} :
                             inst_st_h ? {2{rkd_value[15:0]}} :
                             inst_st_w ? rkd_value            :
                                         32'b0;
endmodule