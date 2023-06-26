module mycpu_top
#(
    parameter FS_TO_DS_BUS_WD = 32,
    parameter DS_TO_ES_BUS_WD = 237,
    parameter ES_TO_MS_BUS_WD = 175,
    parameter MS_TO_WS_BUS_WD = 102,
    parameter WS_TO_RF_BUS_WD = 38,

    parameter MS_TO_ES_BUS_WD = 38,
    parameter WS_TO_ES_BUS_WD = 38,
    parameter BR_BUS_WD       = 33
    
)
(
    input         clk,
    input         resetn,
    output        timer_int,

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
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_we,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    reg         reset;
    always @(posedge clk) reset <= ~resetn;

    wire [FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
    wire [DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
    wire [ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
    wire [MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
    wire [WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;

    wire [MS_TO_ES_BUS_WD -1:0] ms_to_es_bus;
    wire [WS_TO_ES_BUS_WD -1:0] ws_to_es_bus;

    wire [BR_BUS_WD       -1:0] br_bus;

    wire        flush;
    wire        stallreq_es;
    wire        stallreq_ds;
    wire [ 5:0] stall;
    wire        except_en;
    wire [31:0] new_pc;
    wire [31:0] csr_vec_h;

    if_stage if_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .new_pc          (new_pc          ),
        .timer_int       (timer_int       ),
        .csr_vec_h       (csr_vec_h       ),
        .fs_to_ds_bus    (fs_to_ds_bus    ),
        .br_bus          (br_bus          ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_we    (inst_sram_we    ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
    );

    id_stage id_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .br_taken        (br_bus[32]      ),
        .stallreq_ds     (stallreq_ds     ),
        .fs_to_ds_bus    (fs_to_ds_bus    ),
        .pc_valid        (inst_sram_en    ),
        .inst_sram_rdata (inst_sram_rdata ),
        .csr_vec_h       (csr_vec_h       ),
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
        .es_to_ms_bus    (es_to_ms_bus    ),    
        .ms_to_es_bus    (ms_to_es_bus    ),    
        .ws_to_es_bus    (ws_to_es_bus    ),

        .br_bus          (br_bus          ),

        .data_sram_en    (data_sram_en    ),
        .data_sram_we    (data_sram_we    ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata )
    );

    mem_stage mem_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),
        .except_en       (except_en       ),
        .new_pc          (new_pc          ),

        .es_to_ms_bus    (es_to_ms_bus    ),
        .ms_to_es_bus    (ms_to_es_bus    ),
        .ms_to_ws_bus    (ms_to_ws_bus    ),

        .data_sram_rdata (data_sram_rdata )
    );

    wb_stage wb_stage(
        .clk             (clk             ),
        .reset           (reset           ),
        .flush           (flush           ),
        .stall           (stall           ),

        .ms_to_ws_bus    (ms_to_ws_bus    ),
        .ws_to_rf_bus    (ws_to_rf_bus    ),
        .ws_to_es_bus    (ws_to_es_bus    ),

        .debug_wb_pc       (debug_wb_pc      ),
        .debug_wb_rf_we    (debug_wb_rf_we   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata)
    );

    pip_ctrl pip_ctrl(
        .reset           (reset           ),
        .except_en       (except_en       ),
        .stallreq_ds     (stallreq_ds     ),
        .stallreq_es     (stallreq_es     ),
        .stallreq_axi    (1'b0            ), // TODO!
        .flush           (flush           ),
        .stall           (stall           )
    );

endmodule