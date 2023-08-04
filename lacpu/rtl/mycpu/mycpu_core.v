`default_nettype wire

module mycpu_core
#(
    parameter FS_TO_DS_BUS_WD = 34,
    parameter DS_TO_ES_BUS_WD = 301,
    parameter ES_TO_DT_BUS_WD = 340,
    parameter DT_TO_MS_BUS_WD = 271,
    parameter MS_TO_WS_BUS_WD = 172,
    parameter WS_TO_RF_BUS_WD = 38,

    parameter MS_TO_ES_BUS_WD = 38,
    parameter WS_TO_ES_BUS_WD = 38,
    parameter BR_BUS_WD       = 33
    
)
(
    input         clk,
    input         resetn,
    input  [ 7:0] ext_int,

    // inst sram interface
    output        inst_sram_en,
    output [ 3:0] inst_sram_we,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    // cache
    input         stallreq_dcache,
    input         stallreq_icache,
    input         stallreq_uncache,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_we,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    reg         reset;
    reg         br_taken_buffer;
    reg  [31:0] br_target_buffer;

    always @(posedge clk) reset <= ~resetn;

    wire [FS_TO_DS_BUS_WD -1:0] fs1_to_fs2_bus;
    wire [FS_TO_DS_BUS_WD -1:0] fs2_to_ds_bus;
    wire [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
    wire [ES_TO_DT_BUS_WD -1:0] es_to_dts_bus;
    wire [DT_TO_MS_BUS_WD -1:0] dts_to_ms1_bus;
    wire [DT_TO_MS_BUS_WD -1:0] ms1_to_ms2_bus;
    wire [MS_TO_WS_BUS_WD -1:0] ms2_to_ws_bus;
    wire [WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;

    //wire [MS_TO_ES_BUS_WD -1:0] ms1_to_es_bus;
    //wire [MS_TO_ES_BUS_WD -1:0] ms2_to_es_bus;
    //wire [WS_TO_ES_BUS_WD -1:0] ws_to_es_bus;

    wire [BR_BUS_WD       -1:0] br_bus;
    wire [BR_BUS_WD       -1:0] br_bus_real;

    wire        src1_is_forward;
    wire        src2_is_forward;    
    wire [31:0] src1_forward_result;
    wire [31:0] src2_forward_result;

    wire        stallreq_forward;          

    wire        flush;
    wire        stallreq_es;
    wire        stallreq_ds;
    wire [ 5:0] stall;
    wire        except_en;
    wire [31:0] new_pc;

    wire [ 1:0] csr_plv;
    wire        csr_has_int;
    wire        stallreq_cache;
    wire        br_taken;
    wire [31:0] br_target;
    

    assign stallreq_cache = stallreq_dcache | stallreq_icache | stallreq_uncache;

    always @ (posedge clk) begin
        if (reset) begin
            br_taken_buffer  <= 1'b0;
            br_target_buffer <= 32'b0;
        end
        else if (!stall[0]) begin
            br_taken_buffer  <= 1'b0;
            br_target_buffer <= 32'b0;
        end
        else if (!br_taken_buffer) begin
            br_taken_buffer  <= br_bus[32];
            br_target_buffer <= br_bus[31:0];
        end
    end

    assign br_taken    =  br_bus[32] | br_taken_buffer;
    assign br_target   =  br_bus[32]      ? br_bus[31:0]     : 
                          br_taken_buffer ? br_target_buffer :
                                            32'b0;
    assign br_bus_real = {br_taken, br_target};        // TODO!
    

    if1_stage if1_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .new_pc          (new_pc          ),
        .fs1_to_fs2_bus  (fs1_to_fs2_bus  ),
        .br_bus          (br_bus_real     ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_we    (inst_sram_we    ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
    );

    if2_stage if2_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        
        .br_taken        (br_taken        ),
        .fs1_to_fs2_bus  (fs1_to_fs2_bus  ),
        .fs2_to_ds_bus   (fs2_to_ds_bus   )
    );

    id_stage id_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .br_taken        (br_taken        ),
        .stallreq_ds     (stallreq_ds     ),
        .fs2_to_ds_bus   (fs2_to_ds_bus   ),
        .inst_sram_rdata (inst_sram_rdata ),
        .csr_plv         (csr_plv         ),
        .csr_has_int     (csr_has_int     ),
        .ws_to_rf_bus    (ws_to_rf_bus    ),
        .ds_to_es_bus    (ds_to_es_bus    )
    );

    exe_stage exe_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .stallreq_es     (stallreq_es     ),

        .ds_to_es_bus    (ds_to_es_bus    ),    
        .es_to_dts_bus   (es_to_dts_bus   ),

        .src1_is_forward     (src1_is_forward    ),
        .src2_is_forward     (src2_is_forward    ),
        .src1_forward_result (src1_forward_result),
        .src2_forward_result (src2_forward_result),

        //.dts_to_es_bus   (dts_to_es_bus   ),
        //.ms1_to_es_bus   (ms1_to_es_bus   ), 
        //.ms2_to_es_bus   (ms2_to_es_bus   ),    
        //.ws_to_es_bus    (ws_to_es_bus    ),

        .br_bus          (br_bus          ),
        .br_taken_buffer (br_taken_buffer )
    );

    dt_stage dt_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),

        .es_to_dts_bus   (es_to_dts_bus   ),
        .dts_to_ms1_bus  (dts_to_ms1_bus  ),

        //.dts_to_es_bus   (dts_to_es_bus   ),

        .data_sram_en    (data_sram_en    ),
        .data_sram_we    (data_sram_we    ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata )
    );

    mem1_stage mem1_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),

        .dts_to_ms1_bus  (dts_to_ms1_bus  ),
        .ms1_to_ms2_bus  (ms1_to_ms2_bus  )

        //.ms1_to_es_bus   (ms1_to_es_bus   )
    );


    mem2_stage mem2_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .except_en       (except_en       ),
        .new_pc          (new_pc          ),
        .csr_plv         (csr_plv         ),
        .csr_has_int     (csr_has_int     ),
        .stallreq_axi    (stallreq_cache  ),
        .ext_int         (ext_int         ),

        .ms1_to_ms2_bus  (ms1_to_ms2_bus  ),
        //.ms2_to_es_bus   (ms2_to_es_bus   ),
        .ms2_to_ws_bus   (ms2_to_ws_bus   ),

        .data_sram_rdata (data_sram_rdata )
    );

    wb_stage wb_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),

        .ms2_to_ws_bus   (ms2_to_ws_bus   ),
        .ws_to_rf_bus    (ws_to_rf_bus    ),
        .ws_to_es_bus    (ws_to_es_bus    ),

        .debug_wb_pc       (debug_wb_pc      ),
        .debug_wb_rf_we    (debug_wb_rf_we   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata)
    );

    forward forward(
        .clk                 (clk  ),
        .reset               (reset),
        .flush               (flush),
        .stall               (stall),
 
        .rj                  (ds_to_es_bus[174:170] ),
        .rkd                 (ds_to_es_bus[169:165] ),

        .es_reg_we           (es_to_dts_bus[133]     ),
        .es_dest             (es_to_dts_bus[132:128] ),
        .es_result           (es_to_dts_bus[127:96 ] ),
        .es_ctrl             ({(|es_to_dts_bus[142:137] ), (|es_to_dts_bus[195:189] )}),

        .dts_reg_we          (dts_to_ms1_bus[133]    ),
        .dts_dest            (dts_to_ms1_bus[132:128]),
        .dts_result          (dts_to_ms1_bus[127:96 ]),
        .dts_ctrl            ({(|dts_to_ms1_bus[142:137]), (|dts_to_ms1_bus[195:189])}),

        .ms1_reg_we          (ms1_to_ms2_bus[133]    ),
        .ms1_dest            (ms1_to_ms2_bus[132:128]),
        .ms1_result          (ms1_to_ms2_bus[127:96 ]),
        .ms1_ctrl            ({(|ms1_to_ms2_bus[142:137]), (|ms1_to_ms2_bus[195:189])}),

        .ms2_reg_we          (ms2_to_ws_bus[101]     ),
        .ms2_dest            (ms2_to_ws_bus[100:96] ),
        .ms2_result          (ms2_to_ws_bus[95 :64 ] ),
        .ms2_ctrl            (2'b0),
 
        .src1_is_forward     (src1_is_forward        ),
        .src2_is_forward     (src2_is_forward        ),
        .src1_forward_result (src1_forward_result    ),
        .src2_forward_result (src2_forward_result    ),
        .stallreq_forward    (stallreq_forward       )
    );


    pip_ctrl pip_ctrl(
        .reset           (reset           ),
        .except_en       (except_en       ),
        .stallreq_ds     (stallreq_forward),
        .stallreq_es     (stallreq_es     ),
        .stallreq_axi    (stallreq_cache  ),
        //.stallreq_cache  (stallreq_cache  ),
        .flush           (flush           ),
        .stall           (stall           )
    );

endmodule