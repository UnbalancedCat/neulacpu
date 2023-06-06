`include "mycpu.vh"

module loaduse(  
    input  [`DS_TO_LU_BUS_WD -1:0] ds_to_lu_bus,
    input  [`ES_TO_LU_BUS_WD -1:0] es_to_lu_bus,

    output                         lu_to_es_bus
);
    wire [4:0] ds_rf_raddr1;
    wire [4:0] ds_rf_raddr2;
    wire [4:0] es_load_op;
    wire [4:0] es_dest;

    assign {ds_rf_raddr1, ds_rf_raddr2} = ds_to_lu_bus;
    assign {es_dest     , es_load_op  } = es_to_lu_bus;
    
    assign lu_to_es_bus = ^es_load_op && 
                        (((ds_rf_raddr1 == es_dest) && (ds_rf_raddr1 != 5'b0)) || ((ds_rf_raddr2 == es_dest) && (ds_rf_raddr2 != 5'b0)));
endmodule