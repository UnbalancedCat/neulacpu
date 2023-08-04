`include "csr.hv"
module csr(
    input        clk,
    input        reset,
    input        stall,

    input  [31:0] pc,
    input  [31:0] src1,
    input         stallreq_axi,

    input  [31:0] error_va,

    input         csr_we,
    input  [63:0] csr_vec,
    input  [ 6:0] csr_op,
    input  [13:0] csr_addr,
    input         csr_wdata_sel,
    input  [31:0] csr_wdata,

    input  [ 7:0] ext_int,

    output [31:0] csr_rdata,

    output        except_en,
    output [31:0] new_pc,

    output [ 1:0] plv_out,
    output        has_int_out
);
    reg  [31:0] crmd;       // ??????
    reg  [31:0] prmd;       // ???????
    reg  [31:0] euen;       // ??????
    reg  [31:0] ecfg;       // ????
    reg  [31:0] estat;      // ????
    reg  [31:0] era;        // ??????
    reg  [31:0] badv;       // ?????
    reg  [31:0] eentry;     // ??????
    reg  [31:0] tlbidx;     // TLB ??
    reg  [31:0] tlbehi;     // TLB ?????
    reg  [31:0] tlbelo0;    // TLB ???? 0
    reg  [31:0] tlbelo1;    // TLB ???? 1
    reg  [31:0] asid;       // ???????
    reg  [31:0] pgdl;       // ????????????
    reg  [31:0] pgdh;       // ????????????
    reg  [31:0] pgd;        // ??????
    reg  [31:0] cpuid;      // ?????
    reg  [31:0] save0;      // ????0
    reg  [31:0] save1;      // ????1
    reg  [31:0] save2;      // ????2
    reg  [31:0] save3;      // ????3
    reg  [31:0] tid;        // ?????
    reg  [31:0] tcfg;       // ?????
    reg  [31:0] tval;       // ????
    reg  [31:0] ticlr;      // ??????
    reg  [31:0] llbctl;     // LLbit ??
    reg  [31:0] tlbrentry;  // TLB ????????
    reg  [31:0] ctag;       // ??????
    reg  [31:0] dmw0;       // ????????0
    reg  [31:0] dmw1;       // ????????1

    reg  [31:0] csr_rdata_r;

    reg         timer_en;
    reg  [63:0] timer_64;

    wire        inst_sc_w;
    wire        inst_csrrd;
    wire        inst_csrwr;
    wire        inst_csrxchg;
    wire        inst_rdcntid_w;
    wire        inst_rdcntvl_w;
    wire        inst_rdcntvh_w;

    wire        has_int;


    wire        excp_ale;
    wire        excp_adef;
    wire        excp_ipe;
    wire        excp_ine;
    wire        inst_break;
    wire        inst_syscall;
    wire        inst_ertn;

    wire [31:0] csr_wdata_temp;

    wire [ 5:0] ecode;
    wire [ 8:0] esubcode;
    wire        va_error;
    wire [31:0] bad_va;

    assign has_int_out = ((ecfg[`LIE] & estat[`IS]) != 13'b0) & crmd[`IE];
    assign plv_out     = except_en & !inst_ertn             ? 2'b0            :
                         inst_ertn                          ? prmd[`PPLV]     :
                         csr_we && (csr_addr == `CRMD_ADDR) ? csr_wdata[`PLV] :
                                                              crmd[`PLV];

    assign {excp_ale,
            excp_adef,
            excp_ipe, 
            excp_ine, 
            inst_break, 
            inst_syscall, 
            inst_ertn,
            has_int
           } = csr_vec[7:0];

    assign {ecode, esubcode, va_error, bad_va} = excp_adef    ? {`ECODE_ADEF, `ESUBCODE_ADEF, 1'b1, pc      } :
                                                 has_int      ? {`ECODE_INT , 9'b0          , 1'b0, 32'b0   } :
                                                 inst_syscall ? {`ECODE_SYS , 9'b0          , 1'b0, 32'b0   } :
                                                 inst_break   ? {`ECODE_BRK , 9'b0          , 1'b0, 32'b0   } :
                                                 excp_ine     ? {`ECODE_INE , 9'b0          , 1'b0, 32'b0   } :
                                                 excp_ipe     ? {`ECODE_IPE , 9'b0          , 1'b0, 32'b0   } :
                                                 excp_ale     ? {`ECODE_ALE , 9'b0          , 1'b1, error_va} :
                                                                0;

    assign csr_rdata = csr_rdata_r;

    always @(*) begin
        if(|csr_op[6:4]) begin
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
        else if(|csr_op[3:1]) begin
            csr_rdata_r <= ({33{csr_op[1]}} & timer_64[31: 0]) |
                           ({33{csr_op[2]}} & timer_64[63:32]) |
                           ({33{csr_op[3]}} & tid); 
        end
        else begin
           //csr_rdata_r <= 32'b0; 
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

    assign csr_wdata_temp = csr_wdata_sel ? (src1 & csr_wdata) | (~src1 & csr_rdata_r) : csr_wdata;

    always @(posedge clk) begin
        if(reset) begin
                crmd        <= 32'd8;
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
                tcfg        <= 32'hfffffffe;
                tval        <= 0;
                ticlr       <= 0;
                llbctl      <= 0;
                tlbrentry   <= 0;
                ctag        <= 0;
                dmw0        <= 0;
                dmw1        <= 0;

                timer_en    <= 1'b0;
        end
        else if (stallreq_axi) begin
            
        end
        else if(except_en) begin
            if((|csr_vec[7:0] & !inst_ertn) | excp_adef) begin
                crmd[ `PLV] <=  2'b0;
                crmd[  `IE] <=  1'b0;

                prmd[`PPLV] <= crmd[`PLV];
                prmd[ `PIE] <= crmd[`IE ];

                estat[   `ECODE] <= ecode;
                estat[`ESUBCODE] <= esubcode;

                era <= pc;
            end
            else if(inst_ertn) begin
                crmd[ `PLV] <= prmd[`PPLV];
                crmd[  `IE] <= prmd[`PIE ];
            end
            
            if(va_error) begin
               badv <=  bad_va;
            end
        end
        else if (csr_we) begin
            case (csr_addr)
                `CRMD_ADDR      : begin
                                  crmd[ `PLV]     <= csr_wdata_temp[ `PLV];
                                  crmd[  `IE]     <= csr_wdata_temp[  `IE];
                                  crmd[  `DA]     <= csr_wdata_temp[  `DA];
                                  crmd[  `PG]     <= csr_wdata_temp[  `PG];
                                  crmd[`DATF]     <= csr_wdata_temp[`DATF];
                                  crmd[`DATM]     <= csr_wdata_temp[`DATM];
                                  end  
                `PRMD_ADDR      : begin 
                                  prmd[`PPLV]     <= csr_wdata_temp[`PPLV];
                                  prmd[ `PIE]     <= csr_wdata_temp[ `PIE];
                                  end 
                `EUEN_ADDR      : euen	          <= csr_wdata_temp;
                `ECFG_ADDR      : begin 
                                  ecfg            <= csr_wdata_temp;            // ????????????????

                                  end 
                `ESTAT_ADDR     : estat[1:0]      <= csr_wdata_temp[1:0];
                `ERA_ADDR       : era	          <= csr_wdata_temp;
                `BADV_ADDR      : badv	          <= csr_wdata_temp;            // MORE
                `EENTRY_ADDR    : eentry[31:6]	  <= csr_wdata_temp[31:6];
                `TLBIDX_ADDR    : tlbidx	      <= csr_wdata_temp;            // PASS
                `TLBEHI_ADDR    : tlbehi	      <= csr_wdata_temp;            // PASS
                `TLBELO0_ADDR   : tlbelo0	      <= csr_wdata_temp;            // PASS
                `TLBELO1_ADDR   : tlbelo1	      <= csr_wdata_temp;            // PASS
                `ASID_ADDR      : asid[`TLB_ASID] <= csr_wdata_temp[`TLB_ASID]; // MORE
                `PGDL_ADDR      : pgdl	          <= csr_wdata_temp;
                `PGDH_ADDR      : pgdh	          <= csr_wdata_temp;
                `PGD_ADDR       : pgd	          <= csr_wdata_temp;
                //`CPUID_ADDR     : cpuid	      <= csr_wdata_temp;
                `SAVE0_ADDR     : save0	          <= csr_wdata_temp;
                `SAVE1_ADDR     : save1	          <= csr_wdata_temp;
                `SAVE2_ADDR     : save2	          <= csr_wdata_temp;
                `SAVE3_ADDR     : save3	          <= csr_wdata_temp;
                `TID_ADDR       : tid	          <= csr_wdata_temp;
                `TCFG_ADDR      : begin  
                                  tcfg[      `EN] <= csr_wdata_temp[      `EN];
                                  tcfg[`PERIODIC] <= csr_wdata_temp[`PERIODIC];
                                  tcfg[ `INITVAL] <= csr_wdata_temp[ `INITVAL];

                                  tval	          <= {csr_wdata_temp[ `INITVAL], 2'b0};
                                  timer_en        <= csr_wdata_temp[`EN];
                                  end  
                //`TVAL_ADDR      : tval	          <= {csr_wdata_temp[ `INITVAL], 2'b0};
                `TICLR_ADDR     : begin
                                  if(csr_wdata_temp[`CLR]) begin
                                  estat[11]       <= 1'b0;
                                  end
                                  end
                `LLBCTL_ADDR    : llbctl	      <= csr_wdata_temp;            // PASS
                `TLBRENTRY_ADDR : tlbrentry	      <= csr_wdata_temp;            // PASS
                `CTAG_ADDR      : ctag	          <= csr_wdata_temp;
                `DMW0_ADDR      : begin 
                                  dmw0[`PLV0]     <= csr_wdata_temp[`PLV0];
                                  dmw0[`PLV3]     <= csr_wdata_temp[`PLV3];
                                  dmw0[`DMW_MAT]  <= csr_wdata_temp[`DMW_MAT];
                                  dmw0[`PSEG]     <= csr_wdata_temp[`PSEG];
                                  dmw0[`VSEG]     <= csr_wdata_temp[`VSEG];
                                  end 
                `DMW1_ADDR      : begin 
                                  dmw1[`PLV0]     <= csr_wdata_temp[`PLV0];
                                  dmw1[`PLV3]     <= csr_wdata_temp[`PLV3];
                                  dmw1[`DMW_MAT]  <= csr_wdata_temp[`DMW_MAT];
                                  dmw1[`PSEG]     <= csr_wdata_temp[`PSEG];
                                  dmw1[`VSEG]     <= csr_wdata_temp[`VSEG];
                                  end
            endcase
        end
        else begin
            // estat
            if(timer_en && (tval == 32'b0)) begin
                estat[11] <= 1'b1;
                timer_en  <= tcfg[`PERIODIC];
            end
            estat[9:2] <= ext_int; // TODO?
            
            // tval
            if(timer_en) begin
                if (tval != 32'b0) begin
                    tval <= tval - 32'b1;
                end
                else if (tval == 32'b0) begin
                    tval <= tcfg[`PERIODIC] ? {tcfg[`INITVAL], 2'b0} : 32'hffffffff;
                end
            end
        end
    end

    assign except_en = |csr_vec[7:0];
    assign new_pc = (|csr_vec[7:0] & !inst_ertn) | excp_adef ? eentry :
                    inst_ertn                                ? era    :
                                                               32'b0;     // TODO!



    //timer_64
    always @(posedge clk) begin
        if (reset) begin
            timer_64 <= 64'b0;
        end
        else begin
            timer_64 <= timer_64 + 1'b1;
        end
    end

endmodule