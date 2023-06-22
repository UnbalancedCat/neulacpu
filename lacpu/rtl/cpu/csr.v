`define CRMD_ADDR       14'h0
`define PRMD_ADDR       14'h1
`define EUEN_ADDR       14'h2
`define ECFG_ADDR       14'h4
`define ESTAT_ADDR      14'h5
`define ERA_ADDR        14'h6
`define BADV_ADDR       14'h7
`define EENTRY_ADDR     14'hc
`define TLBIDX_ADDR     14'h10
`define TLBEHI_ADDR     14'h11
`define TLBELO0_ADDR    14'h12
`define TLBELO1_ADDR    14'h13
`define ASID_ADDR       14'h18
`define PGDL_ADDR       14'h19
`define PGDH_ADDR       14'h1a
`define PGD_ADDR        14'h1b
`define CPUID_ADDR      14'h20
`define SAVE0_ADDR      14'h30
`define SAVE1_ADDR      14'h31
`define SAVE2_ADDR      14'h32
`define SAVE3_ADDR      14'h33
`define TID_ADDR        14'h40
`define TCFG_ADDR       14'h41
`define TVAL_ADDR       14'h42
`define TICLR_ADDR      14'h44
`define LLBCTL_ADDR     14'h60
`define TLBRENTRY_ADDR  14'h88
`define CTAG_ADDR       14'h98
`define DMW0_ADDR       14'h180
`define DMW1_ADDR       14'h181

module csr(
    input        clk,
    input        reset,
    input        stall,

    input  [31:0] pc,

    input         csr_we,
    input  [ 3:0] csr_op,
    input  [13:0] csr_addr,
    input         csr_wdata_sel,
    input  [31:0] csr_wdata,
    output [31:0] csr_rdata,

    output        except_en,
    output [31:0] new_pc
);
    reg  [31:0] crmd;       // 当前模式信息
    reg  [31:0] prmd;       // 例外前模式信息
    reg  [31:0] euen;       // 扩展部件是能
    reg  [31:0] ecfg;       // 例外配置
    reg  [31:0] estat;      // 例外状态
    reg  [31:0] era;        // 例外返回地址
    reg  [31:0] badv;       // 出错虚地址
    reg  [31:0] eentry;     // 例外入口地址
    reg  [31:0] tlbidx;     // TLB 索引
    reg  [31:0] tlbehi;     // TLB 表项最高位
    reg  [31:0] tlbelo0;    // TLB 表项低位 0
    reg  [31:0] tlbelo1;    // TLB 表项低位 1
    reg  [31:0] asid;       // 地址空间标识符
    reg  [31:0] pgdl;       // 低半地址空间全局目录基址
    reg  [31:0] pgdh;       // 高半地址空间全局目录基址
    reg  [31:0] pgd;        // 全局目录基址
    reg  [31:0] cpuid;      // 处理器编号
    reg  [31:0] save0;      // 数据保存0
    reg  [31:0] save1;      // 数据保存1
    reg  [31:0] save2;      // 数据保存2
    reg  [31:0] save3;      // 数据保存3
    reg  [31:0] tid;        // 定时器编号
    reg  [31:0] tcfg;       // 定时器配置
    reg  [31:0] tval;       // 定时器值
    reg  [31:0] ticlr;      // 定时中断清除
    reg  [31:0] llbctl;     // LLbit 控制
    reg  [31:0] tlbrentry;  // TLB 重填例外入口地址
    reg  [31:0] ctag;       // 高速缓存标签
    reg  [31:0] dmw0;       // 直接映射配置窗口0
    reg  [31:0] dmw1;       // 直接映射配置窗口1

    reg  [31:0] csr_rdata_r;

    wire        inst_sc_w;
    wire        inst_csrrd;
    wire        inst_csrwr;
    wire        inst_csrxchg;
    wire        inst_rdcntid_w;
    wire        inst_rdcntvl_w;
    wire        inst_rdcntvh_w;

    wire [31:0] csr_wdata_temp;


    assign csr_rdata = csr_rdata_r;

    always @(*) begin
        if(|csr_addr) begin
            case(csr_addr)
                `CRMD_ADDR       : csr_rdata_r <= crmd;
                `PRMD_ADDR       : csr_rdata_r <= prmd;
                `EUEN_ADDR       : csr_rdata_r <= euen;
                `ECFG_ADDR       : csr_rdata_r <= ecfg;
                `ESTAT_ADDR      : csr_rdata_r <= estat;
                `ERA_ADDR        : csr_rdata_r <= era;
                `BADV_ADDR       : csr_rdata_r <= badv;
                `EENTRY_ADDR     : csr_rdata_r <= eentry;
                `TLBIDX_ADDR     : csr_rdata_r <= tlbidx;
                `TLBEHI_ADDR     : csr_rdata_r <= tlbehi;
                `TLBELO0_ADDR    : csr_rdata_r <= tlbelo0;
                `TLBELO1_ADDR    : csr_rdata_r <= tlbelo1;
                `ASID_ADDR       : csr_rdata_r <= asid;
                `PGDL_ADDR       : csr_rdata_r <= pgdl;
                `PGDH_ADDR       : csr_rdata_r <= pgdh;
                `PGD_ADDR        : csr_rdata_r <= pgd;
                `CPUID_ADDR      : csr_rdata_r <= cpuid;
                `SAVE0_ADDR      : csr_rdata_r <= save0;
                `SAVE1_ADDR      : csr_rdata_r <= save1;
                `SAVE2_ADDR      : csr_rdata_r <= save2;
                `SAVE3_ADDR      : csr_rdata_r <= save3;
                `TID_ADDR        : csr_rdata_r <= tid;
                `TCFG_ADDR       : csr_rdata_r <= tcfg;
                `TVAL_ADDR       : csr_rdata_r <= tval;
                `TICLR_ADDR      : csr_rdata_r <= ticlr;
                `LLBCTL_ADDR     : csr_rdata_r <= llbctl;
                `TLBRENTRY_ADDR  : csr_rdata_r <= tlbrentry;
                `CTAG_ADDR       : csr_rdata_r <= ctag;
                `DMW0_ADDR       : csr_rdata_r <= dmw0;
                `DMW1_ADDR       : csr_rdata_r <= dmw1;
                default          : csr_rdata_r <= 32'b0;
            endcase
        end
        else begin
           csr_rdata_r <= 32'b0; 
        end
    end

    assign {inst_csrrd,
            inst_csrwr,
            inst_csrxchg,
            inst_rdcntid_w,  
            inst_rdcntvh_w,
            inst_rdcntvl_w,
            inst_sc_w
           } = csr_op;

    assign csr_wdata_temp = csr_wdata_sel ? csr_rdata_r : csr_wdata;

    always @(posedge clk) begin
        if(reset) begin
                crmd        <= 0;
                prmd        <= 0;
                euen        <= 0;
                ecfg        <= 0;
                estat       <= 0;
                era         <= 0;
                badv        <= 0;
                eentry      <= 0;
                tlbidx      <= 0;
                tlbehi      <= 0;
                tlbelo0     <= 0;
                tlbelo1     <= 0;
                asid        <= 0;
                pgdl        <= 0;
                pgdh        <= 0;
                pgd         <= 0;
                cpuid       <= 0;
                save0       <= 0;
                save1       <= 0;
                save2       <= 0;
                save3       <= 0;
                tid         <= 0;
                tcfg        <= 0;
                tval        <= 0;
                ticlr       <= 0;
                llbctl      <= 0;
                tlbrentry   <= 0;
                ctag        <= 0;
                dmw0        <= 0;
                dmw1        <= 0;
        end
        else if (except_en) begin
            // ?
        end
        else if (csr_we) begin
            case (csr_addr)
                `CRMD_ADDR       : crmd	        <= csr_wdata_temp;
                `PRMD_ADDR       : prmd	        <= csr_wdata_temp;
                `EUEN_ADDR       : euen	        <= csr_wdata_temp;
                `ECFG_ADDR       : ecfg	        <= csr_wdata_temp;
                `ESTAT_ADDR      : estat	    <= csr_wdata_temp;
                `ERA_ADDR        : era	        <= csr_wdata_temp;
                `BADV_ADDR       : badv	        <= csr_wdata_temp;
                `EENTRY_ADDR     : eentry	    <= csr_wdata_temp;
                `TLBIDX_ADDR     : tlbidx	    <= csr_wdata_temp;
                `TLBEHI_ADDR     : tlbehi	    <= csr_wdata_temp;
                `TLBELO0_ADDR    : tlbelo0	    <= csr_wdata_temp;
                `TLBELO1_ADDR    : tlbelo1	    <= csr_wdata_temp;
                `ASID_ADDR       : asid	        <= csr_wdata_temp;
                `PGDL_ADDR       : pgdl	        <= csr_wdata_temp;
                `PGDH_ADDR       : pgdh	        <= csr_wdata_temp;
                `PGD_ADDR        : pgd	        <= csr_wdata_temp;
                `CPUID_ADDR      : cpuid	    <= csr_wdata_temp;
                `SAVE0_ADDR      : save0	    <= csr_wdata_temp;
                `SAVE1_ADDR      : save1	    <= csr_wdata_temp;
                `SAVE2_ADDR      : save2	    <= csr_wdata_temp;
                `SAVE3_ADDR      : save3	    <= csr_wdata_temp;
                `TID_ADDR        : tid	        <= csr_wdata_temp;
                `TCFG_ADDR       : tcfg	        <= csr_wdata_temp;
                `TVAL_ADDR       : tval	        <= csr_wdata_temp;
                `TICLR_ADDR      : ticlr	    <= csr_wdata_temp;
                `LLBCTL_ADDR     : llbctl	    <= csr_wdata_temp;
                `TLBRENTRY_ADDR  : tlbrentry	<= csr_wdata_temp;
                `CTAG_ADDR       : ctag	        <= csr_wdata_temp;
                `DMW0_ADDR       : dmw0	        <= csr_wdata_temp;
                `DMW1_ADDR       : dmw1	        <= csr_wdata_temp;
            endcase
        end
    end

    assign except_en = 1'b0; // TODO!
    assign new_pc = era;     // TODO!
endmodule