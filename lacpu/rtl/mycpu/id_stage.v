module id_stage
#(
    parameter FS_TO_DS_BUS_WD = 34,
    parameter DS_TO_ES_BUS_WD = 301,
    parameter WS_TO_RF_BUS_WD = 38
)
(
    input         clk,
    input         reset,

    input         flush,
    input  [ 5:0] stall,
    input         br_taken,

    output        stallreq_ds,

    //input         pc_valid,   
    input  [31:0] inst_sram_rdata,
    input  [ 1:0] csr_plv,
    input         csr_has_int,

    input  [FS_TO_DS_BUS_WD -1:0] fs3_to_ds_bus,
    input  [WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    output [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus
);
    reg  [FS_TO_DS_BUS_WD -1:0] fs2_to_ds_bus_r;
    //reg         pc_valid_r;

    reg  [31:0] inst_sram_rdata_buffer;
    reg  [31:0] inst_sram_rdata_r;
    reg         stall_flag;

    wire        br_flush;
    wire [31:0] ds_pc;

    wire        pc_valid;

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

    wire [ 4:0] rf_raddr1;
    wire [31:0] rf_rdata1;
    wire [ 4:0] rf_raddr2;
    wire [31:0] rf_rdata2;
    wire        rf_we;
    wire [ 4:0] rf_waddr;
    wire [31:0] rf_wdata;

    wire [31:0] rj_value;
    wire [31:0] rkd_value;

    wire        excp_adef;
    wire [31:0] csr_vec_l;
    wire [63:0] csr_vec;

    assign {pc_valid,
            excp_adef,
            ds_pc
           } = fs2_to_ds_bus_r;

    assign csr_vec = {32'b0, csr_vec_l};

    assign br_flush = br_taken;

    assign {rf_we   ,  //37:37
            rf_waddr,  //36:32
            rf_wdata   //31:0
        } = ws_to_rf_bus;

    

    assign ds_to_es_bus = {csr_vec          & {64{pc_valid}}  ,//300:237
                           csr_op                             ,//236:230
                           csr_wdata_sel                      ,//229:229
                           csr_addr                           ,//228:215
                           csr_we                             ,//214:214
                           alu_op                             ,//213:202
                           mul_div_op       & { 4{pc_valid}}  ,//198:189
                           mul_div_sign     &     pc_valid    ,//197:197
                           branch_op        & { 9{pc_valid}}  ,//196:188
                           store_op         & { 3{pc_valid}}  ,//187:185
                           load_op          & { 6{pc_valid}}  ,//184:179
                           reg_we           &     pc_valid    ,//178:178
                           src1_is_pc                         ,//177:177
                           src2_is_imm                        ,//176:176
                           src2_is_4                          ,//175:175
                           rj                                 ,//174:170
                           rkd                                ,//169:165
                           rj_value                           ,//164:133
                           rkd_value                          ,//132:101
                           dest                               ,//100:96
                           imm                                ,//95 :64
                           ds_pc                              ,//63 :32
                           inst             & {32{pc_valid}}   //31 :0
                          };


    always @(posedge clk) begin
        if (reset) begin
            fs2_to_ds_bus_r     <= 0;
            inst_sram_rdata_r   <= 0;
            stall_flag          <= 0;
        end
        else if (flush) begin
            fs2_to_ds_bus_r     <= 0;
            inst_sram_rdata_r   <= 0;
            stall_flag          <= 0;
        end
        else if ((!stall[1]) & (!stall[2]) & br_flush) begin
            fs2_to_ds_bus_r     <= 0;
            inst_sram_rdata_r   <= 0;
            stall_flag          <= 0;
        end
        else if (stall[1] & (!stall[2])) begin
            fs2_to_ds_bus_r     <= 0;
            inst_sram_rdata_r   <= 0;
            stall_flag          <= 0;
        end
        else if ((!stall[1]) & stall_flag) begin
            fs2_to_ds_bus_r     <= fs3_to_ds_bus;
            inst_sram_rdata_r   <= inst_sram_rdata_buffer;
            stall_flag          <= 0;
        end
        else if ((!stall[1]) & (!stall_flag)) begin
            fs2_to_ds_bus_r     <= fs3_to_ds_bus;
            inst_sram_rdata_r   <= inst_sram_rdata;
            stall_flag          <= 0;
        end
        else if ((!stall_flag) & br_flush) begin
            inst_sram_rdata_buffer  <= 0;
            stall_flag              <= 1'b1;
        end
        else if (!stall_flag) begin
            inst_sram_rdata_buffer  <= inst_sram_rdata;
            stall_flag              <= 1'b1;
        end
    end

    assign next_inst = inst_sram_rdata_r;
    assign inst = !pc_valid ? 32'b0 : next_inst;

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
        .excp_adef      (excp_adef      ),
        .csr_plv        (csr_plv        ),
        .csr_has_int    (csr_has_int    ),
        .csr_we         (csr_we         ),
        .csr_op         (csr_op         ),
        .csr_addr       (csr_addr       ),
        .csr_wdata_sel  (csr_wdata_sel  ),
        .csr_vec_l      (csr_vec_l      ),
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

endmodule