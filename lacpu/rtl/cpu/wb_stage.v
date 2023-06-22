module wb_stage
#(
    parameter MS_TO_WS_BUS_WD = 102,
    parameter WS_TO_RF_BUS_WD = 38,
    parameter WS_TO_ES_BUS_WD = 38
)
(
    input        clk,
    input        reset,
    input        flush,
    input  [5:0] stall,

    input  [MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,
    output [WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus,
    output [WS_TO_ES_BUS_WD -1:0] ws_to_es_bus,

    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_we,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
    reg  [MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;

    wire        reg_we;
    wire [ 4:0] dest;
    wire [31:0] ms_final_result;
    wire [31:0] ws_pc;
    wire [31:0] inst;

    assign {reg_we           ,//101:101
            dest             ,//100:96
            ms_final_result  ,//95 :64
            ws_pc            ,//63 :32
            inst              //31 :0
           } = ms_to_ws_bus_r;

    assign ws_to_rf_bus = {reg_we,
                           dest,
                           ms_final_result
                          };

    assign ws_to_es_bus = {reg_we,
                           dest,
                           ms_final_result
                          };

    always @ (posedge clk) begin
        if (reset) begin
            ms_to_ws_bus_r <= 0;
        end
        else if (flush) begin
            ms_to_ws_bus_r <= 0;
        end
        else if (stall[4]&(!stall[5])) begin
            ms_to_ws_bus_r <= 0;
        end
        else if (!stall[4]) begin
            ms_to_ws_bus_r <= ms_to_ws_bus;
        end
    end


    assign debug_wb_pc       = ws_pc;
    assign debug_wb_rf_we    = {4{reg_we}};
    assign debug_wb_rf_wnum  = ms_final_result;
    assign debug_wb_rf_wdata = ms_final_result;

endmodule