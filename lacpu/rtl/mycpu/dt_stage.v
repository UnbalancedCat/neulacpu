module dt_stage 
#(
    parameter ES_TO_DT_BUS_WD = 340,
    parameter DT_TO_MS_BUS_WD = 271,
    parameter MS_TO_ES_BUS_WD = 38
)
(
    input         clk,
    input         reset,
    input         flush,
    input  [ 5:0] stall,

    input  [ES_TO_DT_BUS_WD -1:0] es_to_dts_bus,
    output [DT_TO_MS_BUS_WD -1:0] dts_to_ms1_bus,
    output [MS_TO_ES_BUS_WD -1:0] dts_to_es_bus,

    output        data_sram_en,
    output [ 3:0] data_sram_we,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata
);

    reg  [ES_TO_DT_BUS_WD -1:0] es_to_dts_bus_r;

    wire        reg_we;
    wire [ 4:0] dest;
    wire [31:0] es_result;

    assign dts_to_ms1_bus = es_to_dts_bus_r[DT_TO_MS_BUS_WD -1:0];


    assign {reg_we   ,
            dest     ,  
            es_result
           } = es_to_dts_bus_r[133:96];

    assign {data_sram_en   ,
            data_sram_we   ,
            data_sram_addr ,
            data_sram_wdata
           } = es_to_dts_bus_r[339:271];

    assign dts_to_es_bus = {reg_we,
                            dest,
                            es_result   
                           };

    always @(posedge clk) begin
        if (reset) begin
            es_to_dts_bus_r <= 0;
        end
        else if (flush) begin
            es_to_dts_bus_r <= 0;
        end
        else if(stall[3] & (!stall[4])) begin
            es_to_dts_bus_r <= 0;
        end
        else if(!stall[3]) begin
            es_to_dts_bus_r <= es_to_dts_bus;
        end
    end

endmodule