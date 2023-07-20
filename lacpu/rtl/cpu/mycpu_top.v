`default_nettype wire

module mycpu_top
#(
    parameter HIT_WD       = 2,
    parameter LRU_WD       = 1,
    parameter CACHELINE_WD = 512 
)
(
    input         aclk,
    input         aresetn,
    output        timer_int,

    output [ 3:0] arid,
    output [31:0] araddr,
    output [ 3:0] arlen,
    output [ 2:0] arsize,
    output [ 1:0] arburst,
    output [ 1:0] arlock,
    output [ 3:0] arcache,
    output [ 2:0] arprot,
    output        arvalid,
    input         arready,

    input  [ 3:0] rid,
    input  [31:0] rdata,
    input  [ 1:0] rresp,
    input         rlast,
    input         rvalid,
    output        rready,

    output [ 3:0] awid,
    output [31:0] awaddr,
    output [ 3:0] awlen,
    output [ 2:0] awsize,
    output [ 1:0] awburst,
    output [ 1:0] awlock,
    output [ 3:0] awcache,
    output [ 2:0] awprot,
    output        awvalid,
    input         awready,

    output [ 3:0] wid,
    output [31:0] wdata,
    output [ 3:0] wstrb,
    output        wlast,
    output        wvalid,
    input         wready,

    input  [ 3:0] bid,
    input  [ 1:0] bresp,
    input         bvalid,
    output        bready,
    
    // // inst sram interface
    // output        inst_sram_en,
    // output [ 3:0] inst_sram_we,
    // output [31:0] inst_sram_addr,
    // output [31:0] inst_sram_wdata,
    // input  [31:0] inst_sram_rdata,
    // // data sram interface
    // output        data_sram_en,
    // output [ 3:0] data_sram_we,
    // output [31:0] data_sram_addr,
    // output [31:0] data_sram_wdata,
    // input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_we,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    wire        inst_sram_en;
    wire [ 3:0] inst_sram_we;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire        data_sram_en;
    wire [ 3:0] data_sram_we;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    wire        clk;
    wire        resetn;

    assign clk    = aclk;
    assign resetn = aresetn;

    // icache tag
    wire        icache_cached;
    wire        icache_uncached;
    wire        icache_refresh;
    wire        icache_miss;
    wire [31:0] icache_raddr;
    //wire        icache_write_back;
    wire [31:0] icache_waddr;
    // icache data
    wire [CACHELINE_WD -1:0] icache_cacheline_new;
    wire [CACHELINE_WD -1:0] icache_cacheline_old;


    // dcache tag
    wire        dcache_cached;
    wire        dcache_uncached;
    wire        dcache_refresh;
    wire        dcache_miss;
    wire [31:0] dcache_raddr;
    wire        dcache_write_back;
    wire [31:0] dcache_waddr;
    // dcache data
    wire [CACHELINE_WD -1:0] dcache_cacheline_new;
    wire [CACHELINE_WD -1:0] dcache_cacheline_old;

    // uncache tag
    wire        uncache_refresh;
    wire        uncache_en;
    wire [ 3:0] uncache_we;
    wire [31:0] uncache_addr;
    wire [31:0] uncache_wdata;
    // uncache data
    wire [31:0] uncache_rdata;
    

    wire [31:0] data_sram_addr_mmu;

    wire [31:0] dcache_temp_rdata;
    wire [31:0] uncache_temp_rdata;
    wire stallreq_icache;
    wire stallreq_dcache;
    wire stallreq_uncache;

    mycpu_core mycpu_core(
        .clk                (clk                ),
        .resetn             (resetn             ),

        .inst_sram_en       (inst_sram_en       ),
        .inst_sram_we       (inst_sram_we       ),
        .inst_sram_addr     (inst_sram_addr     ),
        .inst_sram_wdata    (inst_sram_wdata    ),
        .inst_sram_rdata    (inst_sram_rdata    ),

        .data_sram_en       (data_sram_en       ),
        .data_sram_we       (data_sram_we       ),
        .data_sram_addr     (data_sram_addr     ),
        .data_sram_wdata    (data_sram_wdata    ),
        .data_sram_rdata    (data_sram_rdata    ),

        .stallreq_dcache    (stallreq_dcache    ),
        .stallreq_icache    (stallreq_icache    ),
        .stallreq_uncache   (stallreq_uncache   ),

        .debug_wb_pc        (debug_wb_pc        ),
        .debug_wb_rf_we     (debug_wb_rf_we     ),
        .debug_wb_rf_wnum   (debug_wb_rf_wnum   ),
        .debug_wb_rf_wdata  (debug_wb_rf_wdata  )

    );

    icache icache(
        .clk                    (clk                 ),
        .reset                  (~resetn             ),
        .inst_sram_en           (inst_sram_en        ),
        .inst_sram_we           (inst_sram_we        ),
        .inst_sram_addr         (inst_sram_addr      ),
        .inst_sram_wdata        (inst_sram_wdata     ),
        .icache_refresh         (icache_refresh      ),
        .icache_cacheline_new   (icache_cacheline_new),
     
        .stallreq_icache        (stallreq_icache     ),
        .inst_sram_rdata        (inst_sram_rdata     ),
        .icache_miss            (icache_miss         ),
        .icache_raddr           (icache_raddr        ),
        .icache_waddr           (icache_waddr        ),
        .icache_cacheline_old   (icache_cacheline_old)
    );

    dcache dcache(
        .clk                    (clk                 ),
        .reset                  (~resetn             ),
        .data_sram_en           (data_sram_en        ),
        .data_sram_we           (data_sram_we        ),
        .data_sram_addr         (data_sram_addr_mmu  ),
        .data_sram_wdata        (data_sram_wdata     ),
        .dcache_refresh         (dcache_refresh      ),
        .dcache_uncached        (dcache_uncached     ),
        .dcache_cacheline_new   (dcache_cacheline_new),
    
        .stallreq_dcache        (stallreq_dcache     ),
        .data_sram_rdata        (dcache_temp_rdata   ),
        .dcache_miss            (dcache_miss         ),
        .dcache_raddr           (dcache_raddr        ),
        .dcache_waddr           (dcache_waddr        ),
        .dcache_write_back      (dcache_write_back   ),
        .dcache_cacheline_old   (dcache_cacheline_old)
    );

    uncache uncache(
        .clk        (clk                             ),
        .resetn     (resetn                          ),
        .stallreq   (stallreq_uncache                ),
        .conf_en    (data_sram_en & ~dcache_cached   ),
        .conf_we    (data_sram_we                    ),
        .conf_addr  (data_sram_addr_mmu              ), // _mmu ?
        .conf_wdata (data_sram_wdata                 ),
        .conf_rdata (uncache_temp_rdata              ),
        .axi_en     (uncache_en                      ),
        .axi_wsel   (uncache_we                      ),
        .axi_addr   (uncache_addr                    ),
        .axi_wdata  (uncache_wdata                   ),
        .reload     (uncache_refresh                 ),
        .axi_rdata  (uncache_rdata                   )
    );

    reg dcache_cached_r;
    //assign dcache_cached = ~dcache_uncached;
    assign dcache_uncached = ~dcache_cached;
    always @ (posedge clk) begin
        dcache_cached_r <= dcache_cached;
    end
    assign data_sram_rdata = dcache_cached_r ? dcache_temp_rdata : uncache_temp_rdata;


    // mmu u_inst_mmu(
    // 	.addr_i  (inst_sram_addr  ),
    //     .addr_o  (inst_sram_addr_mmu  ),
    //     .cache_v (icache_cached )
    // );
    mmu data_mmu(
    	.addr_i  (data_sram_addr  ),
        .addr_o  (data_sram_addr_mmu  ),
        .cache_v (dcache_cached )
    );


    // cache signal from tlb
    // begin
    //assign dcache_uncached = 1'b0;

    // end

    axi_ctrl_v5 axi_ctrl(
    	.clk                  (clk                  ),
        .reset                (~resetn              ),

        .icache_re            (icache_miss          ),
        .icache_raddr         (icache_raddr         ),
        .icache_cacheline_new (icache_cacheline_new ),
        .icache_we            (1'b0                 ),
        .icache_waddr         (icache_waddr         ),
        .icache_cacheline_old (icache_cacheline_old ),
        .icache_refresh       (icache_refresh       ),

        .dcache_re            (dcache_miss          ),
        .dcache_raddr         (dcache_raddr         ),
        .dcache_cacheline_new (dcache_cacheline_new ),
        .dcache_we            (dcache_write_back    ),
        .dcache_waddr         (dcache_waddr         ),
        .dcache_cacheline_old (dcache_cacheline_old ),
        .dcache_refresh       (dcache_refresh       ),

        .uncache_en           (uncache_en           ),
        .uncache_we           (uncache_we           ),
        .uncache_addr         (uncache_addr         ),
        .uncache_wdata        (uncache_wdata        ),
        .uncache_rdata        (uncache_rdata        ),
        .uncache_refresh      (uncache_refresh      ),

        .arid                 (arid                 ),
        .araddr               (araddr               ),
        .arlen                (arlen                ),
        .arsize               (arsize               ),
        .arburst              (arburst              ),
        .arlock               (arlock               ),
        .arcache              (arcache              ),
        .arprot               (arprot               ),
        .arvalid              (arvalid              ),
        .arready              (arready              ),
        .rid                  (rid                  ),
        .rdata                (rdata                ),
        .rresp                (rresp                ),
        .rlast                (rlast                ),
        .rvalid               (rvalid               ),
        .rready               (rready               ),
        .awid                 (awid                 ),
        .awaddr               (awaddr               ),
        .awlen                (awlen                ),
        .awsize               (awsize               ),
        .awburst              (awburst              ),
        .awlock               (awlock               ),
        .awcache              (awcache              ),
        .awprot               (awprot               ),
        .awvalid              (awvalid              ),
        .awready              (awready              ),
        .wid                  (wid                  ),
        .wdata                (wdata                ),
        .wstrb                (wstrb                ),
        .wlast                (wlast                ),
        .wvalid               (wvalid               ),
        .wready               (wready               ),
        .bid                  (bid                  ),
        .bresp                (bresp                ),
        .bvalid               (bvalid               ),
        .bready               (bready               )
    );

endmodule