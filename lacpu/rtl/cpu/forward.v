`include "mycpu.v"

module forward(
    input                       clk         ,
    input                       reset       ,
    input  [`DS_TO_FW_BUS_WD -1:0] ds_to_fw_bus,
    input  [`ES_TO_FW_BUS_WD -1:0] es_to_fw_bus,
    input  [`MS_TO_FW_BUS_WD -1:0] ms_to_fw_bus,

    output [`FW_TO_ES_BUS_WD -1:0] fw_to_es_bus
);

    reg  [`DS_TO_FW_BUS_WD -1:0] ds_to_fw_bus_r;
    reg  [`ES_TO_FW_BUS_WD -1:0] es_to_fw_bus_r;
    reg  [`MS_TO_FW_BUS_WD -1:0] ms_to_fw_bus_r;

    wire [4:0] ds_rf_raddr1;
    wire [4:0] ds_rf_raddr2;
    wire [4:0] es_rf_raddr2;
    wire [4:0] es_dest;
    wire [4:0] ms_dest;
    
    wire       es_mem_we;
    wire       es_reg_we;
    wire       ms_reg_we;

    wire       src1_is_es_dest;
    wire       src1_is_ms_dest;
    wire       src2_is_es_dest;
    wire       src2_is_ms_dest;
    wire       data_is_rf_wdata;

    assign {ds_rf_raddr1, ds_rf_raddr2                 } = ds_to_fw_bus_r;
    assign {es_rf_raddr2, es_dest, es_reg_we, es_mem_we} = es_to_fw_bus_r;
    assign {ms_dest     , ms_reg_we}                     = ms_to_fw_bus_r;

    assign fw_to_es_bus = {src1_is_es_dest  ,   //4:4
                           src1_is_ms_dest  ,   //3:3
                           src2_is_es_dest  ,   //2:2
                           src2_is_ms_dest  ,   //1:1
                           data_is_rf_wdata     //0:0
                           }; 
    always @(posedge clk) begin
        if(reset) begin
            ds_to_fw_bus_r <= 0;
            es_to_fw_bus_r <= 0;
            ms_to_fw_bus_r <= 0;
        end
        else begin
            ds_to_fw_bus_r <= ds_to_fw_bus;
            es_to_fw_bus_r <= es_to_fw_bus;
            ms_to_fw_bus_r <= ms_to_fw_bus; 
        end
    end

    assign src1_is_ms_dest  = ms_reg_we && (ms_dest != 5'b0) && (es_dest != ds_rf_raddr1) && (ms_dest == ds_rf_raddr1);
    assign src1_is_es_dest  = es_reg_we && (es_dest != 5'b0) &&                              (es_dest == ds_rf_raddr1);
    assign src2_is_ms_dest  = ms_reg_we && (ms_dest != 5'b0) && (es_dest != ds_rf_raddr2) && (ms_dest == ds_rf_raddr2);
    assign src2_is_es_dest  = es_reg_we && (es_dest != 5'b0) &&                              (es_dest == ds_rf_raddr2);
    assign data_is_rf_wdata = ms_reg_we && (ms_dest != 5'b0) &&                              (ms_dest == es_rf_raddr2) && es_mem_we;


endmodule