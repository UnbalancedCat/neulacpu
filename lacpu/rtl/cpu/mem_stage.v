`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    //from data-sram
    input  [31                 :0] data_sram_rdata
);

    reg         ms_valid;
    wire        ms_ready_go;

    reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
    wire [31:0] br_target;
    wire [ 8:0] ms_branch_op;
    wire [ 4:0] ms_load_op;
    wire [ 2:0] ms_store_op;
    wire        ms_mem_to_reg;
    wire        ms_reg_we;
    wire [ 4:0] ms_dest;
    wire [31:0] ms_alu_result;
    wire [31:0] ms_pc;
    wire        ms_Carry     ;
    wire        ms_Sign      ;
    wire        ms_Overflow  ;
    wire        ms_Zero      ;  

    assign {br_target        ,   //120:89
            ms_branch_op     ,   //88 :80  
            ms_Carry         ,   //79 :79
            ms_Sign          ,   //78 :78
            ms_Overflow      ,   //77 :77
            ms_Zero          ,   //76 :76
            ms_load_op       ,   //75 :71
            ms_mem_to_reg    ,   //70 :70
            ms_reg_we        ,   //69 :69
            ms_dest          ,   //68 :64
            ms_alu_result    ,   //63 :32
            ms_pc                //31 :0 
        } = es_to_ms_bus_r;

    wire        br_taken;
    
    wire [31:0] mem_result;
    wire [31:0] ms_final_result;

    assign br_bus       = {br_taken, br_target};

    assign ms_to_ws_bus = {ms_reg_we      ,  //69:69
                           ms_dest        ,  //68:64
                           ms_final_result,  //63:32
                           ms_pc             //31:0
                          };

    assign ms_ready_go    = 1'b1;
    assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
    assign ms_to_ws_valid = ms_valid && ms_ready_go;
    always @(posedge clk) begin
        if (reset) begin
            ms_valid <= 1'b0;
        end
        else if (ms_allowin) begin
            ms_valid <= es_to_ms_valid;
        end

        if (es_to_ms_valid && ms_allowin) begin
            es_to_ms_bus_r  = es_to_ms_bus;
        end
    end

    assign mem_result = (ms_load_op[0] || ms_load_op[3]) ? ((ms_alu_result[1:0] == 2'b00) ? {{24{ms_load_op[3] ? data_sram_rdata[ 7] : 1'b0 }}, data_sram_rdata[ 7:0]       } :
                                                            (ms_alu_result[1:0] == 2'b01) ? {{16{ms_load_op[3] ? data_sram_rdata[ 7] : 1'b0 }}, data_sram_rdata[ 7:0],  8'b0} :
                                                            (ms_alu_result[1:0] == 2'b10) ? {{ 8{ms_load_op[3] ? data_sram_rdata[ 7] : 1'b0 }}, data_sram_rdata[ 7:0], 16'b0} :
                                                                                            {                                                   data_sram_rdata[ 7:0], 24'b0}) :
                        (ms_load_op[1] || ms_load_op[4]) ? ((ms_alu_result[1:0] == 2'b00) ? {{16{ms_load_op[4] ? data_sram_rdata[15] : 1'b0 }}, data_sram_rdata[15:0]       } :
                                                                                            {                                                   data_sram_rdata[15:0], 16'b0}) :
                         ms_load_op[2]                   ? (                                                                                    data_sram_rdata              ) :
                                                             32'b0;

    assign ms_final_result = ms_mem_to_reg ? mem_result
                                           : ms_alu_result;

    assign br_taken  = (   ms_branch_op[0]  &&  ms_Zero
                        || ms_branch_op[1]  && !ms_Zero 
                        || ms_branch_op[2]  && (ms_Sign != ms_Overflow)
                        || ms_branch_op[3]  && (ms_Zero | (ms_Sign == ms_Overflow))
                        || ms_branch_op[4]  &&  ms_Carry
                        || ms_branch_op[5]  && (ms_Zero | ~ms_Carry               )
                        || ms_branch_op[6]
                        || ms_branch_op[7]
                        || ms_branch_op[8]);


endmodule
