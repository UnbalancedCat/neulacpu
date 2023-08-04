module dcache
#(
    parameter HIT_WD       = 2,
    parameter LRU_WD       = 1,
    parameter CACHELINE_WD = 512
)
(
    input         clk,
    input         reset,
    input         data_sram_en,
    input  [ 3:0] data_sram_we,
    input  [31:0] data_sram_addr,
    input  [31:0] data_sram_wdata,
    input         dcache_refresh,
    input         dcache_uncached,
    input  [CACHELINE_WD -1:0] dcache_cacheline_new,
    
    output        stallreq_dcache,
    output [31:0] data_sram_rdata,
    output        dcache_miss,
    output [31:0] dcache_raddr,
    output [31:0] dcache_waddr,
    output        dcache_write_back,
    output [CACHELINE_WD -1:0] dcache_cacheline_old
);

    wire [HIT_WD       -1:0] dcache_hit;
    wire [LRU_WD       -1:0] dcache_lru;


    cache_tag_v5 u_dcache_tag(
    	.clk        (clk                    ),
        .reset      (reset                  ),
        .flush      (1'b0                   ),
        .stallreq   (stallreq_dcache        ),
        .cached     (~dcache_uncached       ),
        .sram_en    (data_sram_en           ),
        .sram_we    (data_sram_we           ),
        .sram_addr  (data_sram_addr         ),
        .refresh    (dcache_refresh         ),
        .miss       (dcache_miss            ),
        .axi_raddr  (dcache_raddr           ),
        .write_back (dcache_write_back      ),
        .axi_waddr  (dcache_waddr           ),
        .hit        (dcache_hit             ),
        .lru        (dcache_lru             ) 
    );

    cache_data_v5 u_dcache_data(
    	.clk           (clk                    ),
        .reset         (reset                  ),
        .write_back    (dcache_write_back      ),
        .hit           (dcache_hit             ),
        .lru           (dcache_lru             ),
        .cached        (~dcache_uncached       ),  
        .sram_en       (data_sram_en           ),
        .sram_we       (data_sram_we           ),
        .sram_addr     (data_sram_addr         ),
        .sram_wdata    (data_sram_wdata        ),
        .sram_rdata    (data_sram_rdata        ),
        .refresh       (dcache_refresh         ),
        .cacheline_new (dcache_cacheline_new   ),
        .cacheline_old (dcache_cacheline_old   )
    );
endmodule