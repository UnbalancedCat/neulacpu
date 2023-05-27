module soc_lite_top
(
    input         resetn, 
    input         clk,
    output [15:0] pc
);
    //debug signals
    wire [31:0] debug_wb_pc;
    wire [3 :0] debug_wb_rf_wen;
    wire [4 :0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;

    //clk and resetn
    wire cpu_clk;
    reg  cpu_resetn;

    assign pc      = debug_wb_pc[15:0];
    assign cpu_clk = clk;
    always @(posedge cpu_clk)
    begin
        cpu_resetn <= resetn;
    end

    //cpu inst sram
    wire        cpu_inst_en;
    wire [3 :0] cpu_inst_wen;
    wire [31:0] cpu_inst_addr;
    wire [31:0] cpu_inst_wdata;
    wire [31:0] cpu_inst_rdata;
    //cpu data sram
    wire        cpu_data_en;
    wire [3 :0] cpu_data_wen;
    wire [31:0] cpu_data_addr;
    wire [31:0] cpu_data_wdata;
    wire [31:0] cpu_data_rdata;
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
   
    //cpu
    mycpu_top cpu(
        .clk              (cpu_clk   ),
        .resetn           (cpu_resetn),  //low active

        .inst_sram_en     (cpu_inst_en   ),
        .inst_sram_wen    (cpu_inst_wen  ),
        .inst_sram_addr   (cpu_inst_addr ),
        .inst_sram_wdata  (cpu_inst_wdata),
        .inst_sram_rdata  (cpu_inst_rdata),
        
        .data_sram_en     (cpu_data_en   ),
        .data_sram_wen    (cpu_data_wen  ),
        .data_sram_addr   (cpu_data_addr ),
        .data_sram_wdata  (cpu_data_wdata),
        .data_sram_rdata  (cpu_data_rdata),

        //div
        .div_divisor_data   (div_divisor_data   ),
        .div_divisor_valid  (div_divisor_valid  ),
        .div_divisor_ready  (div_divisor_ready  ),
        .div_dividend_data  (div_dividend_data  ),
        .div_dividend_valid (div_dividend_valid ),
        .div_dividend_ready (div_dividend_ready ),
        .div_dout_valid     (div_dout_valid     ),
        .div_dout_data      (div_dout_data      ),
        //divu
        .divu_divisor_data  (divu_divisor_data  ),
        .divu_divisor_valid (divu_divisor_valid ),
        .divu_divisor_ready (divu_divisor_ready ),
        .divu_dividend_data (divu_dividend_data ),
        .divu_dividend_valid(divu_dividend_valid),
        .divu_dividend_ready(divu_dividend_ready),
        .divu_dout_valid    (divu_dout_valid    ),
        .divu_dout_data     (divu_dout_data     ),

        //debug
        .debug_wb_pc      (debug_wb_pc      ),
        .debug_wb_rf_wen  (debug_wb_rf_wen  ),
        .debug_wb_rf_wnum (debug_wb_rf_wnum ),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );


    `ifdef DPIC

    
    `else
        //inst ram
        inst_ram inst_ram
        (
            .clka  (cpu_clk            ),   
            .ena   (cpu_inst_en        ),
            .wea   (cpu_inst_wen       ),   //3:0
            .addra (cpu_inst_addr[17:2]),   //15:0
            .dina  (cpu_inst_wdata     ),   //31:0
            .douta (cpu_inst_rdata     )    //31:0
        );

        //data ram
        data_ram data_ram
        (
            .clka  (cpu_clk            ),   
            .ena   (cpu_data_en        ),
            .wea   (cpu_data_wen       ),   //3:0
            .addra (cpu_data_addr[17:2]),   //15:0
            .dina  (cpu_data_wdata     ),   //31:0
            .douta (cpu_data_rdata     )    //31:0
        );

        //div
        div div(
            .aclk                   (cpu_clk            ),
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
            .aclk                   (cpu_clk            ),
            .s_axis_divisor_tdata   (divu_divisor_data  ),
            .s_axis_divisor_tvalid  (divu_divisor_valid ),
            .s_axis_divisor_tready  (divu_divisor_ready ),
            .s_axis_dividend_tdata  (divu_dividend_data ),
            .s_axis_dividend_tvalid (divu_dividend_valid),
            .s_axis_dividend_tready (divu_dividend_ready),
            .m_axis_dout_tvalid     (divu_dout_valid    ),
            .m_axis_dout_tdata      (divu_dout_data     )
        );
    `endif
    
endmodule

