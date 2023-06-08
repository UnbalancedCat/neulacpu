`timescale 1ns / 1ps

module cpu_tb(

    );
    reg         resetn;
    reg         clk;
    wire [31:0] debug_wb_pc;
    wire [ 3:0] debug_wb_rf_wen;
    wire [ 4:0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;
    
    initial
    begin
        clk = 1'b0;
        resetn = 1'b0;
        #20;
        resetn = 1'b1;
        #2000;
        $finish;
    end
    always #5 clk=~clk;
    
    soc_lite_top u_soc_top(
        .resetn             (resetn           ),
        .clk                (clk              ),
        
        .pc                 ()
    );
    
     //debug signals
    assign debug_wb_pc = u_soc_top.debug_wb_pc;
    assign debug_wb_rf_wen = u_soc_top.debug_wb_rf_wen;
    assign debug_wb_rf_wnum = u_soc_top.debug_wb_rf_wnum;
    assign debug_wb_rf_wdata = u_soc_top.debug_wb_rf_wdata;
    
    always @(posedge clk) begin
        $display("PC = 0x%8h, wb_rf_wnum = 0x%2h, wb_rf_wdata = 0x%8h",
                      debug_wb_pc, debug_wb_rf_wnum, debug_wb_rf_wdata);
    end
    
    
endmodule
