`include "mycpu.vh"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    //to fw
    output [`ES_TO_FW_BUS_WD -1:0] es_to_fw_bus  ,
    //from fw
    input  [`FW_TO_ES_BUS_WD -1:0] fw_to_es_bus  ,
    //from ms
    input  [`MS_TO_ES_BUS_WD -1:0] ms_to_ds_bus  ,
    //from ws
    input  [`WS_TO_ES_BUS_WD -1:0] ws_to_ds_bus  ,
    //to lu
    output [`ES_TO_LU_BUS_WD -1:0] es_to_lu_bus  ,
    //from lu
    input                          lu_to_es_bus
);

    reg         es_valid      ;
    wire        es_ready_go   ;

    reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
    wire [18:0] es_alu_op;
    wire        es_src1_is_pc;
    wire        es_src2_is_imm;
    wire        es_src2_is_4;
    wire        es_mem_to_reg;
    wire        es_reg_we;
    wire        es_mem_we;
    wire [ 4:0] es_load_op;
    wire [ 2:0] es_store_op;
    wire [ 8:0] es_branch_op;
    wire [ 4:0] es_dest;
    wire [31:0] es_imm;
    wire [31:0] es_rf_rdata1;
    wire [31:0] es_rf_rdata2;
    wire [31:0] es_pc;

    wire [31:0] ms_alu_result;
    wire [31:0] ws_rf_wdata;

    wire        es_src1_is_es_dest;
    wire        es_src1_is_ms_dest;
    wire        es_src2_is_es_dest;
    wire        es_src2_is_ms_dest;
    wire        es_data_is_rf_wdata;

    wire        lu_to_es_bus_r;
    reg         loaduse_r;

    assign {es_alu_op       ,   //173:155
            es_src1_is_pc   ,   //154:154
            es_src2_is_imm  ,   //153:153
            es_src2_is_4    ,   //152:152
            es_mem_to_reg   ,   //151:151
            es_reg_we       ,   //150:150
            es_mem_we       ,   //149:149
            es_load_op      ,   //148:142
            es_store_op     ,   //141:141
            es_branch_op    ,   //141:133
            es_dest         ,   //132:128
            es_imm          ,   //127:96
            es_rf_rdata1    ,   //95 :64
            es_rf_rdata2    ,   //63 :32
            es_pc               //31 :0
            } = ds_to_es_bus_r;

    assign {es_src1_is_es_dest ,
            es_src1_is_ms_dest ,
            es_src2_is_es_dest ,
            es_src2_is_ms_dest ,
            es_data_is_rf_wdata
            } = fw_to_es_bus;

    assign ms_alu_result = ms_to_ds_bus;
    assign ws_rf_wdata   = ws_to_ds_bus;    

    wire [31:0] br_target;

    wire [31:0] es_alu_src1  ;
    wire [31:0] es_alu_src2  ;
    wire [31:0] es_alu_result;
    wire        es_Carry     ;
    wire        es_Sign      ;
    wire        es_Overflow  ;
    wire        es_Zero      ;  
    wire [31:0] es_result    ;

    reg         div_divisor_valid_r;
    reg         div_divisor_ready_flag;
    reg         div_dividend_valid_r;
    reg         div_dividend_ready_flag;
    reg         divu_divisor_valid_r;
    reg         divu_divisor_ready_flag;
    reg         divu_dividend_valid_r;
    reg         divu_dividend_ready_flag;

    wire        es_inst_divw ;
    wire        es_inst_modw ;
    wire        es_inst_divwu;
    wire        es_inst_modwu; 
    wire        is_div_mod;

    wire [31:0] div_mod_result;

    //div
    wire [31:0] div_divisor_data;
    wire        div_divisor_valid;
    wire        div_divisor_ready;
    wire [31:0] div_dividend_data;
    wire        div_dividend_valid;
    wire        div_dividend_ready;
    wire        div_dout_valid;
    wire [63:0] div_dout_data;
    //divu
    wire [31:0] divu_divisor_data;
    wire        divu_divisor_valid;
    wire        divu_divisor_ready;
    wire [31:0] divu_dividend_data;
    wire        divu_dividend_valid;
    wire        divu_dividend_ready;
    wire        divu_dout_valid;
    wire [63:0] divu_dout_data;

    assign es_result = is_div_mod ? div_mod_result : es_alu_result;

    assign es_to_ms_bus = {br_target        ,   //120:89
                           es_branch_op     ,   //88 :80  
                           es_Carry         ,   //79 :79
                           es_Sign          ,   //78 :78
                           es_Overflow      ,   //77 :77
                           es_Zero          ,   //76 :76
                           es_load_op       ,   //75 :71
                           es_mem_to_reg    ,   //70 :70
                           es_reg_we        ,   //69 :69
                           es_dest          ,   //68 :64
                           es_result        ,   //63 :32
                           es_pc                //31 :0 
                          };

    assign es_to_fw_bus = {es_rf_rdata2 , 
                           es_dest      ,
                           es_reg_we    , 
                           es_mem_we     
                           };

    assign es_to_lu_bus  = {es_dest, es_load_op};

    assign es_ready_go    = (is_div_mod && !(div_dout_valid || divu_dout_valid)) || loaduse_r ? 1'b1 : 1'b0;
    assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
    assign es_to_ms_valid =  es_valid && es_ready_go;
    always @(posedge clk) begin
        if (reset) begin
            es_valid <= 1'b0;
        end
        else if (es_allowin) begin
            es_valid <= ds_to_es_valid;
        end

        if (ds_to_es_valid && es_allowin) begin
            ds_to_es_bus_r <= ds_to_es_bus;
        end
    end

    always @(posedge clk) begin
        if(reset) begin
            loaduse_r <= 1'b0;
        end
        else if(loaduse_r == 1'b1) begin
            loaduse_r <= 1'b0;
        end
        else begin
            loaduse_r <= lu_to_es_bus;
        end
    end

    assign es_alu_src1 = es_src1_is_pc      ? es_pc         :
                         es_src1_is_es_dest ? ms_alu_result :
                         es_src1_is_ms_dest ? ws_rf_wdata   :
                                              es_rf_rdata1;
    assign es_alu_src2 = es_src2_is_imm     ? es_imm        : 
                         es_src2_is_4       ? 32'd4         :
                         es_src2_is_es_dest ? ms_alu_result :
                         es_src2_is_ms_dest ? ws_rf_wdata   :
                                              es_rf_rdata2;

    assign is_div_mod    = es_inst_divw | es_inst_modw | es_inst_divwu | es_inst_modwu; 
    assign es_inst_divw  = es_alu_op[15];
    assign es_inst_modw  = es_alu_op[16];
    assign es_inst_divwu = es_alu_op[17];
    assign es_inst_modwu = es_alu_op[18];

    assign div_divisor_data   = es_alu_src1;
    assign div_dividend_data  = es_alu_src2;
    assign divu_divisor_data  = es_alu_src1;
    assign divu_dividend_data = es_alu_src2;
    
    always @(posedge clk) begin
        if(reset) begin
            div_divisor_valid_r   <= 1'b0;
            div_divisor_ready_flag  <= 1'b0;
        end
        else if(div_divisor_valid_r && div_divisor_ready) begin
            div_divisor_valid_r   <= 1'b0;
            div_divisor_ready_flag  <= 1'b1;
        end
        else if((es_inst_divw || es_inst_modw) && !div_divisor_ready_flag) begin
            div_divisor_valid_r   <= 1'b1;
        end
        else if(es_ready_go) begin
            div_divisor_ready_flag  <= 1'b0;
        end
    end
    always @(posedge clk) begin
        if(reset) begin
            div_dividend_valid_r   <= 1'b0;
            div_dividend_ready_flag  <= 1'b0;
        end
        else if(div_dividend_valid_r && div_dividend_ready) begin
            div_dividend_valid_r   <= 1'b0;
            div_dividend_ready_flag  <= 1'b1;
        end
        else if((es_inst_divw || es_inst_modw) && !div_dividend_ready_flag) begin
            div_dividend_valid_r   <= 1'b1;
        end
        else if(es_ready_go) begin
            div_dividend_ready_flag  <= 1'b0;
        end
    end
    always @(posedge clk) begin
        if(reset) begin
            divu_divisor_valid_r   <= 1'b0;
            divu_divisor_ready_flag  <= 1'b0;
        end
        else if(divu_divisor_valid_r && divu_divisor_ready) begin
            divu_divisor_valid_r   <= 1'b0;
            divu_divisor_ready_flag  <= 1'b1;
        end
        else if((es_inst_divw || es_inst_modw) && !divu_divisor_ready_flag) begin
            divu_divisor_valid_r   <= 1'b1;
        end
        else if(es_ready_go) begin
            divu_divisor_ready_flag  <= 1'b0;
        end
    end
    always @(posedge clk) begin
        if(reset) begin
            divu_dividend_valid_r   <= 1'b0;
            divu_dividend_ready_flag  <= 1'b0;
        end
        else if(divu_dividend_valid_r && divu_dividend_ready) begin
            divu_dividend_valid_r   <= 1'b0;
            divu_dividend_ready_flag  <= 1'b1;
        end
        else if((es_inst_divw || es_inst_modw) && !divu_dividend_ready_flag) begin
            divu_dividend_valid_r   <= 1'b1;
        end
        else if(es_ready_go) begin
            divu_dividend_ready_flag  <= 1'b0;
        end
    end

    //div
    div div(
        .aclk                   (clk                ),
        .s_axis_divisor_tdata   (div_divisor_data   ),
        .s_axis_divisor_tvalid  (div_divisor_valid  ),
        .s_axis_divisor_tready  (div_divisor_ready  ),
        .s_axis_dividend_tdata  (div_dividend_data  ),
        .s_axis_dividend_tvalid (div_dividend_valid ),
        .s_axis_dividend_tready (div_dividend_ready ),
        .m_axis_dout_tvalid     (div_dout_valid     ),
        .m_axis_dout_tdata      (div_dout_data      )
    );

    //divu
    divu divu(
        .aclk                   (clk                ),
        .s_axis_divisor_tdata   (divu_divisor_data  ),
        .s_axis_divisor_tvalid  (divu_divisor_valid ),
        .s_axis_divisor_tready  (divu_divisor_ready ),
        .s_axis_dividend_tdata  (divu_dividend_data ),
        .s_axis_dividend_tvalid (divu_dividend_valid),
        .s_axis_dividend_tready (divu_dividend_ready),
        .m_axis_dout_tvalid     (divu_dout_valid    ),
        .m_axis_dout_tdata      (divu_dout_data     )
    );

    assign div_divisor_valid  = div_divisor_valid_r;
    assign div_dividend_valid  = div_dividend_valid_r;
    assign divu_divisor_valid = divu_divisor_valid_r;
    assign divu_dividend_valid = divu_dividend_valid_r;

    assign div_mod_result = es_inst_divw  ? div_dout_data[63:32]  :
                            es_inst_modw  ? div_dout_data[31: 0]  :
                            es_inst_divwu ? divu_dout_data[63:32] :
                            es_inst_modwu ? divu_dout_data[31: 0] :
                                            32'b0;

    alu u_alu(
        .alu_op     (es_alu_op[14:0]),
        .alu_src1   (es_alu_src1  ),
        .alu_src2   (es_alu_src2  ),
        .alu_result (es_alu_result),

        .Carry      (es_Carry    ),
        .Sign       (es_Sign     ),
        .Overflow   (es_Overflow ),   
        .Zero       (es_Zero     )
        );

    assign data_sram_en    = 1'b1;
    assign data_sram_wen   = (es_mem_we && es_valid) ? (({4{es_store_op[0]}} & ({4{es_alu_result[1:0] == 2'b00}} & 4'b0001)
                                                                             | ({4{es_alu_result[1:0] == 2'b01}} & 4'b0010)
                                                                             | ({4{es_alu_result[1:0] == 2'b10}} & 4'b0100)
                                                                             | ({4{es_alu_result[1:0] == 2'b11}} & 4'b1000))
                                                      | ({4{es_store_op[1]}} & ({4{es_alu_result[1:0] == 2'b01}} & 4'b0011)
                                                                             | ({4{es_alu_result[1:0] == 2'b10}} & 4'b1100))
                                                      | ({4{es_store_op[2]}}                                     & 4'b1111 ))
                                                                                                                 : 4'b0000;
                                
    assign data_sram_addr  = es_alu_result;
    assign data_sram_wdata = es_data_is_rf_wdata ?    ws_rf_wdata          : 
                             es_store_op[0]      ? {4{es_rf_rdata2[ 7:0]}} :
                             es_store_op[1]      ? {2{es_rf_rdata2[15:0]}} :
                             es_store_op[2]      ?    es_rf_rdata2         :
                                                      32'b0;

    assign br_target =  (^es_branch_op[5:0]) ? (es_pc        + es_imm) :
                        ( es_branch_op[7:6]) ? (es_pc        + es_imm) :
                        ( es_branch_op[8]  ) ? (es_rf_rdata1 + es_imm) :
                                                0;

endmodule