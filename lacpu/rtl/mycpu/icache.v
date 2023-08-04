module icache
#(
    parameter HIT_WD       = 2,
    parameter LRU_WD       = 1,
    parameter CACHELINE_WD = 512
)
(
    input         clk,
    input         reset,
    input         inst_sram_en,
    input  [ 3:0] inst_sram_we,
    input  [31:0] inst_sram_addr,
    input  [31:0] inst_sram_wdata,
    input         icache_refresh,
    input  [CACHELINE_WD -1:0] icache_cacheline_new,
    
    output        stallreq_icache,
    output [31:0] inst_sram_rdata,
    output        icache_miss,
    output [31:0] icache_raddr,
    output [31:0] icache_waddr,
    output [CACHELINE_WD -1:0] icache_cacheline_old
);

    wire [HIT_WD       -1:0] icache_hit;
    wire [LRU_WD       -1:0] icache_lru;
    
    cache_tag_v5 u_icache_tag(
    	.clk        (clk                    ),
        .reset      (reset                  ),
        .flush      (1'b0                   ),
        .stallreq   (stallreq_icache        ),
        .cached     (1'b1                   ),
        .sram_en    (inst_sram_en           ),
        .sram_we    (inst_sram_we           ),
        .sram_addr  (inst_sram_addr         ),
        .refresh    (icache_refresh         ),
        .miss       (icache_miss            ),
        .axi_raddr  (icache_raddr           ),
        .write_back (/*icache_write_back*/  ), // no use
        .axi_waddr  (icache_waddr           ),
        .hit        (icache_hit             ),
        .lru        (icache_lru             )
    );

    cache_data_v5 u_icache_data(
    	.clk           (clk                    ),
        .reset         (reset                  ),
        .write_back    (1'b0                   ),
        .hit           (icache_hit             ),
        .lru           (icache_lru             ),
        .cached        (1'b1                   ),
        .sram_en       (inst_sram_en           ),
        .sram_we       (inst_sram_we           ),
        .sram_addr     (inst_sram_addr         ),
        .sram_wdata    (inst_sram_wdata        ),
        .sram_rdata    (inst_sram_rdata        ),
        .refresh       (icache_refresh         ),
        .cacheline_new (icache_cacheline_new   ),
        .cacheline_old (icache_cacheline_old   ) 
    );

endmodule