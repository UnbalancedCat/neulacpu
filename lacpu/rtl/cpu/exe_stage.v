`include "mycpu.h"

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
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata
);

    reg         es_valid      ;
    wire        es_ready_go   ;

    reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
    wire [11:0] es_alu_op;
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
    wire [31:0] es_pc         ;


    assign {es_alu_op       ,   //158:147
            es_src1_is_pc   ,   //146:146
            es_src2_is_imm  ,   //145:145
            es_src2_is_4    ,   //144:144
            es_mem_to_reg   ,   //143:143
            es_reg_we       ,   //142:142
            es_mem_we       ,   //141:141
            es_load_op      ,   //140:136
            es_store_op     ,   //135:133
            es_branch_op    ,
            es_dest         ,   //132:128
            es_imm          ,   //127:96
            es_rf_rdata1    ,   //95 :64
            es_rf_rdata2    ,   //63 :32
            es_pc               //31 :0
            } = ds_to_es_bus_r;

    wire        br_taken;
    wire [31:0] br_target;

    wire [31:0] es_alu_src1  ;
    wire [31:0] es_alu_src2  ;
    wire [31:0] es_alu_result;
    wire        es_Carry     ;
    wire        es_Sign      ;
    wire        es_Overflow  ;
    wire        es_Zero      ;  

    assign br_bus       = {br_taken,br_target};

    assign es_to_ms_bus = {es_load_op       ,   //75:71
                           es_mem_to_reg    ,   //70:70
                           es_reg_we        ,   //69:69
                           es_dest          ,   //68:64
                           es_alu_result    ,   //63:32
                           es_pc                //31:0
                          };

    assign es_ready_go    = 1'b1;
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

    assign es_alu_src1 = es_src1_is_pc  ? es_pc :
                                        es_rf_rdata1;
    assign es_alu_src2 = es_src2_is_imm ? es_imm : 
                        es_src2_is_4   ? 32'd4  :
                                        es_rf_rdata2;

    alu u_alu(
        .alu_op     (es_alu_op    ),
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
    assign data_sram_wdata = es_store_op[0] ? {4{es_rf_rdata2[ 7:0]}} :
                             es_store_op[1] ? {2{es_rf_rdata2[15:0]}} :
                             es_store_op[2] ?    es_rf_rdata2         :
                                                32'b0;

    assign br_taken  = (   es_branch_op[0]  &&  es_Zero
                        || es_branch_op[1]  && !es_Zero 
                        || es_branch_op[2]  && (es_Sign != es_Overflow)
                        || es_branch_op[3]  && (es_Zero | (es_Sign == es_Overflow))
                        || es_branch_op[4]  &&  es_Carry
                        || es_branch_op[5]  && (es_Zero | ~es_Carry               )
                        || es_branch_op[6]
                        || es_branch_op[7]
                        || es_branch_op[8]);
    assign br_target =  (^es_branch_op[5:0]) ? (es_pc        + es_imm) :
                        ( es_branch_op[7:6]) ? (es_pc        + es_imm) :
                        ( es_branch_op[8]  ) ? (es_rf_rdata1 + es_imm) :
                                                0;

endmodule