`include "mycpu.v"

// 译码阶段
module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to fs
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus  ,
    //to fw
    output [`DS_TO_FW_BUS_WD -1:0] ds_to_fw_bus

);

    reg         ds_valid   ;
    wire        ds_ready_go;

    wire [31                 :0] fs_pc;
    reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;
    assign fs_pc = fs_to_ds_bus[31:0];

    wire [31:0] ds_inst;
    wire [31:0] ds_pc  ;
    assign {ds_inst,
            ds_pc  } = fs_to_ds_bus_r;

    wire        rf_we   ;
    wire [ 4:0] rf_waddr;
    wire [31:0] rf_wdata;
    assign {rf_we   ,  //37:37
            rf_waddr,  //36:32
            rf_wdata   //31:0
        } = ws_to_rf_bus;

    wire [11:0] alu_op;
    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        src2_is_4;
    wire        mem_to_reg;
    wire        reg_we;
    wire        mem_we;
    wire [ 4:0] load_op;
    wire [ 2:0] store_op;
    wire [ 8:0] branch_op;
    wire [ 4:0] dest;
    wire [31:0] imm;

    wire [21:0] op;
    wire [ 4:0] ra;
    wire [ 4:0] rk;
    wire [ 4:0] rj;
    wire [ 4:0] rd;
    wire [ 7:0] op6_d;
    wire [ 7:0] op7_d;
    wire [ 7:0] op10_d;
    wire [31:0] op17_d;

    wire        inst_addw;
    wire        inst_subw;
    wire        inst_addiw;
    wire        inst_lu12iw;
    wire        inst_slt;
    wire        inst_sltu;
    wire        inst_slti;
    wire        inst_sltui;
    wire        inst_pcaddu12i;
    wire        inst_and;
    wire        inst_or;
    wire        inst_nor;
    wire        inst_xor;
    wire        inst_andi;
    wire        inst_ori;
    wire        inst_xori;
    wire        inst_sllw;
    wire        inst_srlw;
    wire        inst_sraw;
    wire        inst_slliw;
    wire        inst_srliw;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_blt;
    wire        inst_bge;
    wire        inst_bltu;
    wire        inst_bgeu;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_jirl;
    wire        inst_ldb;
    wire        inst_ldh;
    wire        inst_ldw;
    wire        inst_ldbu;
    wire        inst_ldhu;
    wire        inst_stb;
    wire        inst_sth;
    wire        inst_stw;

    wire        dst_is_r1;   

    wire [ 4:0] rf_raddr1;
    wire [31:0] rf_rdata1;
    wire [ 4:0] rf_raddr2;
    wire [31:0] rf_rdata2;

    wire        rj_eq_rd;
    wire        rj_lt_rd;
    wire        rj_ltu_rd;

    assign ds_to_es_bus = {alu_op       ,   //166:155
                           src1_is_pc   ,   //154:154
                           src2_is_imm  ,   //153:153
                           src2_is_4    ,   //152:152
                           mem_to_reg   ,   //151:151
                           reg_we       ,   //150:150
                           mem_we       ,   //149:149
                           load_op      ,   //148:142
                           store_op     ,   //141:141
                           branch_op    ,   //141:133
                           dest         ,   //132:128
                           imm          ,   //127:96
                           rf_rdata1    ,   //95 :64
                           rf_rdata2    ,   //63 :32
                           ds_pc            //31 :0
                          };

    assign ds_to_fw_bus = {rf_raddr1 , rf_raddr2};

    assign ds_ready_go    = 1'b1;
    assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
    assign ds_to_es_valid = ds_valid && ds_ready_go;
    always @(posedge clk) begin

        if (reset) begin
            ds_valid <= 1'b0;
        end
        else if (ds_allowin) begin
            ds_valid <= fs_to_ds_valid;
        end

        if (fs_to_ds_valid && ds_allowin) begin
            fs_to_ds_bus_r <= fs_to_ds_bus;
        end
    end

    assign op   = ds_inst[31:10];
    assign ra   = ds_inst[19:15];
    assign rk   = ds_inst[14:10];
    assign rj   = ds_inst[ 9: 5];
    assign rd   = ds_inst[ 4: 0];

    decoder_3_8  u_dec0(.in(op[18:16]), .out(op6_d ));
    decoder_3_8  u_dec1(.in(op[17:15]), .out(op7_d ));
    decoder_3_8  u_dec2(.in(op[14:12]), .out(op10_d));
    decoder_5_32 u_dec3(.in(ra       ), .out(op17_d));

    assign inst_addw        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b00000];
    assign inst_subw        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b00001];
    assign inst_slt         = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b00100];
    assign inst_sltu        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b00101];
    assign inst_nor         = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01000];
    assign inst_and         = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01001];
    assign inst_or          = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01010];
    assign inst_xor         = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01011];
    assign inst_sllw        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01110];
    assign inst_srlw        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b01111];
    assign inst_sraw        = (op[21: 5] == 12'b0000_0000_0001) & op17_d[5'b10000];
    assign inst_slliw       = (op[21: 5] == 12'b0000_0000_0100) & op17_d[5'b00001];
    assign inst_srliw       = (op[21: 5] == 12'b0000_0000_0100) & op17_d[5'b01001];
    assign inst_sraiw       = (op[21: 5] == 12'b0000_0000_0100) & op17_d[5'b10001];
    assign inst_slti        = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b000];
    assign inst_sltui       = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b001];
    assign inst_addiw       = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b010];
    assign inst_andi        = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b101];
    assign inst_ori         = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b110];
    assign inst_xori        = (op[21:11] ==  7'b0000_001      ) & op10_d[3'b111];
    assign inst_ldb         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b000];
    assign inst_ldh         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b001];
    assign inst_ldw         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b010];
    assign inst_stb         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b100];
    assign inst_sth         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b101];
    assign inst_stw         = (op[21:11] ==  7'b0010_100      ) & op10_d[3'b110];
    assign inst_ldbu        = (op[21:11] ==  7'b0010_101      ) & op10_d[3'b000];
    assign inst_ldhu        = (op[21:11] ==  7'b0010_101      ) & op10_d[3'b001];
    assign inst_lu12iw      = (op[21:17] ==  4'b0001          ) &  op7_d[3'b010];
    assign inst_pcaddu12i   = (op[21:17] ==  4'b0001          ) &  op7_d[3'b110];
    assign inst_jirl        = (op[21:15] ==  3'b010           ) &  op6_d[3'b011];
    assign inst_b           = (op[21:15] ==  3'b010           ) &  op6_d[3'b100];
    assign inst_bl          = (op[21:15] ==  3'b010           ) &  op6_d[3'b101];
    assign inst_beq         = (op[21:15] ==  3'b010           ) &  op6_d[3'b110];
    assign inst_bne         = (op[21:15] ==  3'b010           ) &  op6_d[3'b111];
    assign inst_blt         = (op[21:15] ==  3'b011           ) &  op6_d[3'b000];
    assign inst_bge         = (op[21:15] ==  3'b011           ) &  op6_d[3'b001];
    assign inst_bltu        = (op[21:15] ==  3'b011           ) &  op6_d[3'b010];
    assign inst_bgeu        = (op[21:15] ==  3'b011           ) &  op6_d[3'b011];

    assign alu_op[ 0] = inst_addw   | inst_addiw | inst_pcaddu12i | inst_ldb | inst_ldh | inst_ldbu | inst_ldhu | inst_ldw | inst_stb | inst_sth | inst_stw | inst_bl | inst_jirl;
    assign alu_op[ 1] = inst_subw;
    assign alu_op[ 2] = inst_slt    | inst_slti;
    assign alu_op[ 3] = inst_sltu   | inst_sltui;
    assign alu_op[ 4] = inst_and    | inst_andi;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or     | inst_ori;
    assign alu_op[ 7] = inst_xor    | inst_xori;
    assign alu_op[ 8] = inst_sllw   | inst_slliw;
    assign alu_op[ 9] = inst_srlw   | inst_srliw;
    assign alu_op[10] = inst_sraw   | inst_sraiw;
    assign alu_op[11] = inst_lu12iw;

    assign imm  =     {32{inst_slti   | inst_sltui | inst_addiw | inst_ldb  | inst_ldh | inst_ldw  | inst_stb | inst_sth | inst_stw | inst_ldbu | inst_ldhu}} & {{20{ds_inst[21]}}, ds_inst[21:10]} 
                    | {32{inst_beq    | inst_bne   | inst_bge   | inst_bgeu | inst_blt | inst_bltu | inst_jirl}} & {{14{ds_inst[25]}}, ds_inst[25:10], 2'b0}
                    | {32{inst_andi   | inst_ori   | inst_xori }} & { 20'b0         , ds_inst[21:10]}
                    | {32{inst_lu12iw | inst_pcaddu12i         }} & { ds_inst[24: 5], 12'b0}
                    | {32{inst_slliw  | inst_srliw | inst_sraiw}} & { 27'b0         , rk}
                    | {32{inst_b      | inst_bl}}                 & {{4{ds_inst[9]}}, ds_inst[9:0], ds_inst[25:10], 2'b0};

    assign src1_is_pc   = inst_bl        | inst_jirl   | inst_pcaddu12i;
    assign src2_is_4    = inst_bl        | inst_jirl;
    assign src2_is_imm  = inst_addiw     | inst_lu12iw | inst_pcaddu12i | inst_andi | inst_ori | inst_xori | inst_slliw | inst_srliw | inst_sraiw | inst_ldb | inst_ldh | inst_ldw | inst_ldbu | inst_ldhu | inst_stb | inst_sth | inst_stw;
    assign dst_is_r1    = inst_bl;

    assign reg_we       = ~(inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu | inst_b | inst_stw | inst_sth | inst_stb);
    assign mem_we       =   inst_stw | inst_sth | inst_stb;
    assign mem_to_reg   =   inst_ldw | inst_ldh | inst_ldb | inst_ldhu | inst_ldbu;
    assign load_op      =  {inst_ldhu, inst_ldbu, inst_ldw, inst_ldh, inst_ldb};
    assign store_op     =  {inst_stw , inst_sth , inst_stb};
    assign branch_op    =  {inst_jirl, inst_bl  , inst_b  , inst_bgeu, inst_bltu, inst_bge, inst_blt, inst_bne, inst_beq};

    assign dest         = dst_is_r1 ? 5'd1 :
                                      rd;

    assign rf_raddr1 = rj;
    assign rf_raddr2 = (inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu) ? rd : rk;
    regfile u_regfile(
        .clk    (clk      ),
        .raddr1 (rf_raddr1),
        .rdata1 (rf_rdata1),
        .raddr2 (rf_raddr2),
        .rdata2 (rf_rdata2),
        .we     (rf_we    ),
        .waddr  (rf_waddr ),
        .wdata  (rf_wdata )
        );

endmodule