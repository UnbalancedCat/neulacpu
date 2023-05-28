`include "mycpu.v"

module loaduse(
    input                          clk,
    input                          reset,
    
    input  [`DS_TO_LU_BUS_WD -1:0] ds_to_lu_bus,
    input  [`ES_TO_LU_BUS_WD -1:0] es_to_lu_bus,

    output                         loaduse
);
    wire [4:0] ds_rf_raddr1;
    wire [4:0] ds_rf_raddr2;
    wire [4:0] es_load_op;
    wire [4:0] es_dest;
    
    reg [`DS_TO_LU_BUS_WD -1:0] ds_to_lu_bus_reg;
    reg [`ES_TO_LU_BUS_WD -1:0] es_to_lu_bus_reg;

    wire loaduse;
    
    always @(posedge clk) begin
        if(reset) begin
            ds_to_lu_bus_reg <= 0;
            es_to_lu_bus_reg <= 0;
        end
        else begin
            ds_to_lu_bus_reg <= ds_to_lu_bus;
            es_to_lu_bus_reg <= es_to_lu_bus;
        end
    end


    assign {ds_rf_rdata1, ds_rf_rdata2} = ds_to_lu_bus_reg;
    assign {es_dest     , es_load_op  } = es_to_lu_bus_reg;
    
    assign loaduse = ^es_load_op && 
                 (((ds_rf_rdata1 == es_dest) && (ds_rf_rdata1 != 5'b0)) || ((ds_rf_rdata2 == es_dest) && (ds_rf_rdata2 != 5'b0)));
endmodule