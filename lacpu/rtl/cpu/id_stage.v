module id_stage
#(
    parameter FS_TO_DS_BUS_WD = 32,
    parameter DS_TO_ES_BUS_WD = 206,
    parameter WS_TO_RF_BUS_WD = 38
)
(
    input         clk,
    input         reset,

    input         flush,
    input  [ 5:0] stall,
    input         br_taken,

    output        stallreq_id,

    input         pc_valid,   
    input  [31:0] inst_sram_rdata,
    input  [31:0] csr_vec_h,

    input  [FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus,
    input  [WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    output [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus
);
    reg         pc_valid_r;
    reg  [31:0] fs_to_ds_bus_r;
    reg  [31:0] csr_vec_h_r;

    reg  [31:0] inst_r;
    reg         stall_flag;

    reg  [ 6:0] ex_load_buffer;
    reg         ex_csr_buffer;

    wire        br_flush;
    wire [31:0] ds_pc;

    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        src2_is_4;
    wire        src_reg_is_rd;
    wire [ 4:0] rj;
    wire [ 4:0] rk;
    wire [ 4:0] rd;
    wire [ 4:0] rkd;
    wire [31:0] imm;
    wire [ 4:0] dest;
    wire [11:0] alu_op;
    wire [ 3:0] mul_div_op;
    wire        mul_div_sign;
    wire [ 8:0] branch_op;
    wire [ 5:0] load_op;
    wire [ 2:0] store_op;
    wire        reg_we;

    wire        csr_we;
    wire [ 6:0] csr_op; 
    wire [13:0] csr_addr;
    wire        csr_wdata_sel;


    wire [31:0] inst;
    wire [31:0] next_inst;

    wire        rf_raddr1;
    wire [31:0] rf_rdata1;
    wire        rf_raddr2;
    wire [31:0] rf_rdata2;
    wire        rf_we;
    wire        rf_waddr;
    wire [31:0] rf_wdata;

    wire [31:0] rj_value;
    wire [31:0] rkd_value;

    wire [ 4:0] ex_rf_waddr;
    wire        ex_is_load;
    wire        ex_is_csr;
    wire        ex_rf_we;
    wire        stallreq_load;
    wire        stallreq_csr;

    assign ds_pc    = fs_to_ds_bus_r;
    assign br_flush = br_taken;
    assign {rf_we   ,  //37:37
            rf_waddr,  //36:32
            rf_wdata   //31:0
        } = ws_to_rf_bus;

    wire csr_vec_l;
    assign csr_vec_l = 0; //TODO!

    assign csr_vec = {csr_vec_h_r, csr_vec_l};
    assign ds_to_es_bus = {csr_op                               ,//205:199
                           csr_wdata_sel                        ,//198:198
                           csr_addr                             ,//197:184
                           csr_we                               ,//183:183
                           alu_op                               ,//182:171
                           mul_div_op       & {4{pc_valid_r}}   ,//170:167
                           mul_div_sign     & pc_valid_r        ,//166:166
                           branch_op        & {9{pc_valid_r}}   ,//165:157
                           store_op         & {3{pc_valid_r}}   ,//156:154
                           load_op          & {6{pc_valid_r}}   ,//153:148
                           reg_we           & pc_valid_r        ,//147:147
                           src1_is_pc                           ,//146:146
                           src2_is_imm                          ,//145:145
                           src2_is_4                            ,//144:144
                           rj                                   ,//143:139
                           rkd                                  ,//138:134
                           rj_value                             ,//133:102
                           rkd_value                            ,//101:70
                           dest                                 ,//69 :65
                           imm                                  ,//95 :64
                           ds_pc                                ,//63 :32
                           inst             & {32{pc_valid_r}}   //31 :0
                          };

    always @ (posedge clk)begin
        if (reset) begin
            pc_valid_r <= 1'b0;
            fs_to_ds_bus_r <= 32'b0;
            csr_vec_h_r <= 32'b0;
        end
        else if (flush) begin
            pc_valid_r <= 1'b0;
            fs_to_ds_bus_r <= 32'b0;
            csr_vec_h_r <= 32'b0;
        end
        //nop, ID stall and EX not stall
        else if (stall[1] & (!stall[2]))begin
            pc_valid_r <= 1'b0;
            fs_to_ds_bus_r <= 32'b0;
            csr_vec_h_r <= 32'b0;
        end
        //nop, ID not stall but branch
        else if (!stall[1] & br_flush) begin
            pc_valid_r <= 1'b0;
            fs_to_ds_bus_r <= 32'b0;
            csr_vec_h_r <= 32'b0;
        end
        // ID not stall so go on
        else if (!stall[1]) begin
            pc_valid_r <= pc_valid;
            fs_to_ds_bus_r <= fs_to_ds_bus;
            csr_vec_h_r <= csr_vec_h;
        end
    end

    always @ (posedge clk) begin
        if (reset) begin
            inst_r <= 64'b0;
            stall_flag <= 1'b0;
        end
        else if (flush) begin
            inst_r <= 64'b0;
            stall_flag <= 1'b0;
        end
        //if not stall, get inst from inst_sram
        else if (!stall[1]) begin
            inst_r <= inst_sram_rdata;
            stall_flag <= 1'b0;
        end
        else if (stall_flag) begin

        end
        //if stall and id stall, get inst from inst_ram ?
        else if (stall[1]&stall[2]) begin
            inst_r <= inst_sram_rdata;
            stall_flag <= 1'b1;
        end
    end

    assign next_inst = stall_flag ? inst_r : inst_sram_rdata;
    assign inst = ~pc_valid_r ? 32'b0 : next_inst;

    inst_decoder u_inst_decoder(
        .inst           (inst           ),

        .src1_is_pc     (src1_is_pc     ),
        .src2_is_imm    (src2_is_imm    ),
        .src2_is_4      (src2_is_4      ),
        .src_reg_is_rd  (src_reg_is_rd  ),
        .rj             (rj             ),
        .rk             (rk             ),
        .rd             (rd             ),
        .imm            (imm            ),
        .dest           (dest           ),
        .alu_op         (alu_op         ),
        .mul_div_op     (mul_div_op     ),
        .mul_div_sign   (mul_div_sign   ),
        .branch_op      (branch_op      ),
        .load_op        (load_op        ),
        .store_op       (store_op       ),
        .csr_we         (csr_we         ),
        .csr_op         (csr_op         ),
        .csr_addr       (csr_addr       ),
        .csr_wdata_sel  (csr_wdata_sel  ),
        .sel_rf_res     (sel_rf_res     ),
        .reg_we         (reg_we         )
    );

    assign rf_raddr1 = rj;
    assign rf_raddr2 = src_reg_is_rd ? rd : rk;
    assign rkd       = src_reg_is_rd ? rd : rk;

    regfile u_regfile(
        .clk    (clk      ),
        .reset  (reset    ),
        .raddr1 (rf_raddr1),
        .rdata1 (rf_rdata1),
        .raddr2 (rf_raddr2),
        .rdata2 (rf_rdata2),
        .we     (rf_we    ),
        .waddr  (rf_waddr ),
        .wdata  (rf_wdata )
        );

    assign rj_value  = rf_rdata1;
    assign rkd_value = rf_rdata2;


    always @ (posedge clk) begin
        if (reset) begin
            ex_load_buffer <= 7'b0;
            ex_csr_buffer <= 1'b0;
        end
        else if (flush) begin
            ex_load_buffer <= 7'b0;
            ex_csr_buffer <= 1'b0;
        end
        else if (stall[2]&(!stall[3])) begin
            ex_load_buffer <= 7'b0;
            ex_csr_buffer <= 1'b0;
        end
        else if (!stall[2]) begin
            ex_load_buffer <= {|load_op, rf_we, rf_waddr};
            ex_csr_buffer <= |csr_op;
        end
    end

    assign {ex_is_load,
            ex_rf_we,
            ex_rf_waddr
           } = ex_load_buffer;
    assign ex_is_csr = ex_csr_buffer;
    //ex段为load指令，且发生数据相关时，id段需要被暂停
    assign stallreq_load = ex_is_load & ex_rf_we & ((ex_rf_waddr==rj_value & rj_value!=0)|(ex_rf_waddr==rkd_value & rkd_value!=0));
    assign stallreq_csr  = ex_is_csr  & ex_rf_we & ((ex_rf_waddr==rj_value & rj_value!=0)|(ex_rf_waddr==rkd_value & rkd_value!=0));
    assign stallreq_id   = stallreq_load | stallreq_csr;


endmodule