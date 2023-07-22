module exe_stage
#(
    parameter BR_BUS_WD = 33,
    parameter DS_TO_ES_BUS_WD = 301,
    parameter ES_TO_MS_BUS_WD = 271,
    parameter MS_TO_ES_BUS_WD = 38,
    parameter WS_TO_ES_BUS_WD = 38
)
(
    input         clk,
    input         reset,
    input         flush,
    input  [ 5:0] stall,

    output        stallreq_es,

    input  [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus,    
    output [ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,    
    input  [MS_TO_ES_BUS_WD -1:0] ms_to_es_bus,    
    input  [WS_TO_ES_BUS_WD -1:0] ws_to_es_bus,

    output [BR_BUS_WD       -1:0] br_bus,

    output        data_sram_en,
    output [ 3:0] data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata
);

    reg [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;

    wire [63:0] csr_vec;
    wire [63:0] csr_vec_temp;
    wire [ 6:0] csr_op;
    wire        csr_wdata_sel;
    wire [13:0] csr_addr;
    wire        csr_we;
    wire [11:0] alu_op;
    wire [ 3:0] mul_div_op;
    wire        mul_div_sign;
    wire [ 8:0] branch_op;
    wire [ 2:0] store_op;
    wire [ 5:0] load_op;
    wire        reg_we;
    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        src2_is_4;
    wire [ 4:0] rj;
    wire [ 4:0] rkd;
    wire [31:0] rj_value;
    wire [31:0] rkd_value;
    wire [ 4:0] dest;
    wire [31:0] imm;
    wire [31:0] es_pc;
    wire [31:0] inst;

    wire        ms_reg_we;
    wire [ 4:0] ms_dest;
    wire [31:0] ms_result;
    wire        ws_reg_we;
    wire [ 4:0] ws_dest;
    wire [31:0] ws_result;

    wire [31:0] src1;
    wire [31:0] src2;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0] alu_result;

    wire        br_taken;
    wire [31:0] br_target;
    wire        br_flush;

    wire        data_sram_en_temp;
    wire [ 3:0] data_sram_we_temp;

    wire        stallreq_for_mul_div;
    wire [31:0] mul_div_result;
    wire [31:0] es_result;

    wire [31:0] csr_wdata;
    wire [63:0] csr_bus;
    
    wire        excp_adef;  
    wire        excp_ale;

    assign {csr_vec_temp     ,//300:237
            csr_op           ,//236:230
            csr_wdata_sel    ,//229:229
            csr_addr         ,//228:215
            csr_we           ,//214:214
            alu_op           ,//213:202
            mul_div_op       ,//198:189
            mul_div_sign     ,//197:197
            branch_op        ,//196:188
            store_op         ,//187:185
            load_op          ,//184:179
            reg_we           ,//178:178
            src1_is_pc       ,//177:177
            src2_is_imm      ,//176:176
            src2_is_4        ,//175:175
            rj               ,//174:170
            rkd              ,//169:165
            rj_value         ,//164:133
            rkd_value        ,//132:101
            dest             ,//100:96
            imm              ,//95 :64
            es_pc            ,//63 :32
            inst              //31 :0
           } = ds_to_es_bus_r;

    assign {ms_reg_we,
            ms_dest,
            ms_result
           } = ms_to_es_bus;

    assign {ws_reg_we,
            ws_dest,
            ws_result
           } = ws_to_es_bus;

    assign es_to_ms_bus = {csr_vec  ,//270:207
                           csr_bus  ,//206:143
                           load_op  ,//142:137
                           store_op ,//136:134
                           reg_we   ,//133:133
                           dest     ,//132:128
                           es_result,//127:96
                           src1     ,//95 :64
                           es_pc    ,//63 :32
                           inst      //31 :0
                          };
    
    assign br_flush = br_taken & ~(csr_cancel|csr_cancel_reg);

    assign excp_adef = csr_vec[6];

    always @ (posedge clk) begin
        if (reset) begin
            ds_to_es_bus_r <= 0;
        end
        else if (flush) begin
            ds_to_es_bus_r <= 0;
        end
        //nop, id stall and ex not stall
        else if (stall[2]&(!stall[3])) begin
            ds_to_es_bus_r <= 0;
        end
        //nop, id not stall and br_bus[32]
        else if (!stall[2]&br_flush) begin
            ds_to_es_bus_r <= 0;
        end
        // id not stall so can go on
        else if (!stall[2]) begin
            ds_to_es_bus_r <= ds_to_es_bus;
        end
    end

    assign src1 = ms_reg_we & (ms_dest == rj ) & (rj  != 1'b0) ? ms_result :
                  ws_reg_we & (ws_dest == rj ) & (rj  != 1'b0) ? ws_result :
                                                                 rj_value;
    assign src2 = ms_reg_we & (ms_dest == rkd) & (rkd != 1'b0) ? ms_result :
                  ws_reg_we & (ws_dest == rkd) & (rkd != 1'b0) ? ws_result :
                                                                 rkd_value;
    
    assign alu_src1 = src1_is_pc ? es_pc :
                                   src1;
    assign alu_src2 = src2_is_4   ? 3'd4 :
                      src2_is_imm ? imm  :
                                    src2;

    alu u_alu(
        .alu_op    (alu_op    ),
        .alu_src1  (alu_src1  ),
        .alu_src2  (alu_src2  ),
        .alu_result(alu_result)
    );

    bru u_bru(
        .pc       (es_pc    ),
        .rj_value (src1     ),
        .rkd_value(src2     ),
        .imm      (imm      ),
        .branch_op(branch_op),
        .br_taken (br_taken ),
        .br_target(br_target)
    );
    
    wire csr_cancel;
    reg  csr_cancel_reg;
    
    assign csr_cancel = /*flush ? 1'b0 :*/ |csr_vec[31:0] | excp_adef;// TODO!

    always @ (posedge clk) begin
        if (reset) begin
            csr_cancel_reg <= 0;
        end
        else if (flush) begin
            csr_cancel_reg <= 0;
        end
        else if (csr_cancel) begin
            csr_cancel_reg <= 1;
        end
    end
    
    assign br_bus = {br_taken & ~(csr_cancel|csr_cancel_reg),
                     br_target
                    };

    lsu u_lsu(
        .load_op        (load_op          ),
        .store_op       (store_op         ),
        .rj_value       (src1             ),
        .rkd_value      (src2             ),
        .imm            (imm              ),

        .excp_ale       (excp_ale         ),

        .data_sram_en   (data_sram_en_temp),
        .data_sram_we   (data_sram_we_temp),
        .data_sram_addr (data_sram_addr   ),
        .data_sram_wdata(data_sram_wdata  )
    );
    assign data_sram_en = (csr_cancel|csr_cancel_reg) ? 1'b0 : data_sram_en_temp;
    assign data_sram_we = {4{data_sram_en}} & data_sram_we_temp;

    // mul_div
    mul_div_top u_mul_div_top(
        .clk           (clk                 ),
        .reset         (reset | flush       ),
        .stall         (stall               ),
        .stallreq      (stallreq_for_mul_div),
        .mul_div_op    (mul_div_op          ),
        .mul_div_sign  (mul_div_sign        ),
        .a             (alu_src1            ),
        .b             (alu_src2            ),
        .mul_div_result(mul_div_result      )
    );

    assign es_result = (|mul_div_op         ) ? mul_div_result :
                       (|load_op | |store_op) ? data_sram_addr :
                                                alu_result;
    
    assign csr_wdata = src2;
    assign csr_bus = {csr_we,
                      csr_wdata_sel,
                      csr_op,
                      csr_addr,
                      csr_wdata
                     };

    assign csr_vec = {csr_vec_temp[63:8], excp_ale, csr_vec_temp[6:0]};

    assign stallreq_es = stallreq_for_mul_div;

endmodule