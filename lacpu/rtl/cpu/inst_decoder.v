module inst_decoder(
    input  [31:0] inst,

    output        src1_is_pc,
    output        src2_is_imm,
    output        src2_is_4,
    output        src_reg_is_rd,
    output [ 4:0] rj,
    output [ 4:0] rk,
    output [ 4:0] rd,
    output [31:0] imm,
    output [ 4:0] dest,

    // alu
    output [11:0] alu_op,

    // mul div
    output [ 3:0] mul_div_op,
    output        mul_div_sign,

    // branch
    output [ 8:0] branch_op,
    output [ 5:0] load_op,
    output [ 2:0] store_op,

    // csr
    input         excp_adef,
    input  [ 1:0] csr_plv,
    input         csr_has_int,

    output        csr_we,
    output [ 6:0] csr_op,
    output [13:0] csr_addr,
    output        csr_wdata_sel,
    output [31:0] csr_vec_l,

    //output [ 3:0] sel_rf_res,

    output       reg_we
);
    wire        dest_is_r1;
    wire        dest_is_rj;
    
    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;
    wire [31:0] rd_d;
    wire [31:0] rj_d;
    wire [31:0] rk_d;
    wire [11:0] i12;
    wire [13:0] i14;
    wire [19:0] i20;
    wire [15:0] i16;
    wire [25:0] i26;
    wire [13:0] csr_idx;

    wire inst_add_w; 
    wire inst_sub_w;  
    wire inst_slt;    
    wire inst_sltu;   
    wire inst_nor;    
    wire inst_and;    
    wire inst_or;     
    wire inst_xor;     
    wire inst_lu12i_w;
    wire inst_addi_w;
    wire inst_slti;
    wire inst_sltui;
    wire inst_pcaddi;
    wire inst_pcaddu12i;
    //wire inst_andn;
    //wire inst_orn;
    wire inst_andi;
    wire inst_ori;
    wire inst_xori;
    wire inst_mul_w;
    wire inst_mulh_w;
    wire inst_mulh_wu;
    wire inst_div_w;
    wire inst_mod_w;
    wire inst_div_wu;
    wire inst_mod_wu;

    wire inst_slli_w;  
    wire inst_srli_w;  
    wire inst_srai_w;  
    wire inst_sll_w;
    wire inst_srl_w;
    wire inst_sra_w;

    wire inst_jirl;   
    wire inst_b;      
    wire inst_bl;     
    wire inst_beq;    
    wire inst_bne; 
    wire inst_blt;
    wire inst_bge;
    wire inst_bltu;
    wire inst_bgeu;

    wire inst_ll_w;
    wire inst_sc_w;
    wire inst_ld_b;
    wire inst_ld_bu;
    wire inst_ld_h;
    wire inst_ld_hu;
    wire inst_ld_w;
    wire inst_st_b;
    wire inst_st_h;
    wire inst_st_w;

    wire inst_syscall;
    wire inst_break;
    wire inst_csrrd;
    wire inst_csrwr;
    wire inst_csrxchg;
    wire inst_ertn;

    wire inst_rdcntid_w;
    wire inst_rdcntvl_w;
    wire inst_rdcntvh_w;
    //wire inst_idle;

    //wire inst_tlbsrch;
    //wire inst_tlbrd;
    //wire inst_tlbwr;
    //wire inst_tlbfill;
    //wire inst_invtlb;

    //wire inst_cacop;
    //wire inst_preld;
    wire inst_dbar;
    wire inst_ibar;

    wire need_ui5;
    wire need_si12;
    wire need_ui12;
    wire need_si14_pc;
    wire need_si16_pc;
    wire need_si20;
    wire need_si20_pc;
    wire need_si26_pc;

    wire inst_valid;
    wire excp_ine;
    
    wire kernel_inst;
    wire excp_ipe;


    assign op_31_26  = inst[31:26];
    assign op_25_22  = inst[25:22];
    assign op_21_20  = inst[21:20];
    assign op_19_15  = inst[19:15];

    assign rd   = inst[ 4: 0];
    assign rj   = inst[ 9: 5];
    assign rk   = inst[14:10];

    assign i12  = inst[21:10];
    assign i14  = inst[23:10];
    assign i20  = inst[24: 5];
    assign i16  = inst[25:10];
    assign i26  = {inst[ 9: 0], inst[25:10]};

    assign csr_idx = inst[23:10];

    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
    decoder_5_32 u_dec5(.in(rj  ), .out(rj_d  ));
    decoder_5_32 u_dec6(.in(rk  ), .out(rk_d  ));

    assign inst_add_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_sltu       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_nor        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_or         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_xor        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    //assign inst_orn        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0c];
    //assign inst_andn       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0d];
    assign inst_sll_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
    assign inst_srl_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
    assign inst_sra_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
    assign inst_mul_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
    assign inst_mulh_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
    assign inst_mulh_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
    assign inst_div_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
    assign inst_mod_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
    assign inst_div_wu     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
    assign inst_mod_wu     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];
    assign inst_break      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];
    assign inst_syscall    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
    assign inst_slli_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srli_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_srai_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    //assign inst_idle       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    //assign inst_invtlb     = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h13];
    assign inst_dbar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h04];
    assign inst_ibar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h05];
    assign inst_slti       = op_31_26_d[6'h00] & op_25_22_d[4'h8];
    assign inst_sltui      = op_31_26_d[6'h00] & op_25_22_d[4'h9];
    assign inst_addi_w     = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_andi       = op_31_26_d[6'h00] & op_25_22_d[4'hd];
    assign inst_ori        = op_31_26_d[6'h00] & op_25_22_d[4'he];
    assign inst_xori       = op_31_26_d[6'h00] & op_25_22_d[4'hf];
    assign inst_ld_b       = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
    assign inst_ld_h       = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
    assign inst_ld_w       = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_b       = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
    assign inst_st_h       = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
    assign inst_st_w       = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_ld_bu      = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
    assign inst_ld_hu      = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
    //assign inst_cacop      = op_31_26_d[6'h01] & op_25_22_d[4'h8];
    //assign inst_preld      = op_31_26_d[6'h0a] & op_25_22_d[4'hb];
    assign inst_jirl       = op_31_26_d[6'h13];
    assign inst_b          = op_31_26_d[6'h14];
    assign inst_bl         = op_31_26_d[6'h15];
    assign inst_beq        = op_31_26_d[6'h16];
    assign inst_bne        = op_31_26_d[6'h17];
    assign inst_blt        = op_31_26_d[6'h18];
    assign inst_bge        = op_31_26_d[6'h19];
    assign inst_bltu       = op_31_26_d[6'h1a];
    assign inst_bgeu       = op_31_26_d[6'h1b];
    assign inst_lu12i_w    = op_31_26_d[6'h05] & ~inst[25];
    assign inst_pcaddi     = op_31_26_d[6'h06] & ~inst[25];
    assign inst_pcaddu12i  = op_31_26_d[6'h07] & ~inst[25];
    assign inst_csrxchg    = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & (~rj_d[5'h00] & ~rj_d[5'h01]);  //rj != 0,1
    assign inst_ll_w       = op_31_26_d[6'h08] & ~inst[25] & ~inst[24];
    assign inst_sc_w       = op_31_26_d[6'h08] & ~inst[25] &  inst[24];
    assign inst_csrrd      = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & rj_d[5'h00];
    assign inst_csrwr      = op_31_26_d[6'h01] & ~inst[25] & ~inst[24] & rj_d[5'h01];
    assign inst_rdcntid_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rd_d[5'h00];
    assign inst_rdcntvl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rj_d[5'h00] & !rd_d[5'h00];
    assign inst_rdcntvh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h19] & rj_d[5'h00];
    assign inst_ertn       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0e] & rj_d[5'h00] & rd_d[5'h00];
    //assign inst_tlbsrch    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0a] & rj_d[5'h00] & rd_d[5'h00];
    //assign inst_tlbrd      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0b] & rj_d[5'h00] & rd_d[5'h00];
    //assign inst_tlbwr      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0c] & rj_d[5'h00] & rd_d[5'h00];
    //assign inst_tlbfill    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0d] & rj_d[5'h00] & rd_d[5'h00];


    assign src_reg_is_rd = inst_beq    | 
                           inst_bne    | 
                           inst_blt    | 
                           inst_bltu   | 
                           inst_bge    | 
                           inst_bgeu   |
                           inst_st_b   |
                           inst_st_h   |
                           inst_st_w   |
                           inst_sc_w   |
                           inst_csrwr  |
                           inst_csrxchg;

    assign src1_is_pc    = inst_jirl   |
                           inst_bl     |
                           inst_pcaddi |
                           inst_pcaddu12i;

    assign src2_is_imm   = inst_slli_w    |
                           inst_srli_w    |
                           inst_srai_w    |
                           inst_addi_w    |
                           inst_slti      |
                           inst_sltui     |
                           inst_andi      |
                           inst_ori       |
                           inst_xori      |
                           inst_pcaddi    |
                           inst_pcaddu12i |
                           inst_ld_b      |
                           inst_ld_h      |
                           inst_ld_w      |
                           inst_ld_bu     |
                           inst_ld_hu     |
                           inst_st_b      |
                           inst_st_h      |
                           inst_st_w      |
                           inst_ll_w      |
                           inst_sc_w      |
                           inst_lu12i_w   ;
                           //inst_cacop     |
                           //inst_preld     ;

    assign src2_is_4     = inst_jirl |
                           inst_bl;

    assign dest_is_r1 = inst_bl;
    assign dest_is_rj = inst_rdcntid_w;
    assign dest = (dest_is_r1) ? 5'd1 :
                  (dest_is_rj) ? rj   : 
                                 rd;


    // alu_op
    assign alu_op[ 0] = inst_add_w    | 
                        inst_addi_w   | 
                        //inst_ld_b     |
                        //inst_ld_h     |
                        //inst_ld_w     |
                        //inst_st_b     |
                        //inst_st_h     | 
                        //inst_st_w     |
                        //inst_ld_bu    |
                        //inst_ld_hu    | 
                        //inst_ll_w     |
                        //inst_sc_w     |
                        inst_jirl     | 
                        inst_bl       |
                        inst_pcaddi   |
                        inst_pcaddu12i;
                        //inst_cacop    |
                        //inst_preld    ;

    assign alu_op[ 1] = inst_sub_w;
    assign alu_op[ 2] = inst_slt   | inst_slti;
    assign alu_op[ 3] = inst_sltu  | inst_sltui;
    assign alu_op[ 4] = inst_and   | inst_andi;
    assign alu_op[ 5] = inst_nor;
    assign alu_op[ 6] = inst_or    | inst_ori;
    assign alu_op[ 7] = inst_xor   | inst_xori;
    assign alu_op[ 8] = inst_sll_w | inst_slli_w;
    assign alu_op[ 9] = inst_srl_w | inst_srli_w;
    assign alu_op[10] = inst_sra_w | inst_srai_w;
    assign alu_op[11] = inst_lu12i_w;
    //assign alu_op[12] = inst_andn;
    //assign alu_op[13] = inst_orn;

    // imm
    assign need_ui5      =  inst_slli_w | inst_srli_w | inst_srai_w;
    assign need_si12     =  inst_addi_w |
                            inst_ld_b   |
                            inst_ld_h   |
                            inst_ld_w   |
                            inst_st_b   |
                            inst_st_h   | 
                            inst_st_w   |
                            inst_ld_bu  |
                            inst_ld_hu  | 
                            inst_slti   | 
                            inst_sltui;
                            //inst_cacop  |
                            //inst_preld  ;

    assign need_ui12     =  inst_andi | inst_ori | inst_xori;
    assign need_si14_pc  =  inst_ll_w | inst_sc_w;
    assign need_si16_pc  =  inst_jirl |
                            inst_beq  | 
                            inst_bne  | 
                            inst_blt  | 
                            inst_bge  | 
                            inst_bltu | 
                            inst_bgeu;

    assign need_si20     =  inst_lu12i_w | inst_pcaddu12i;
    assign need_si20_pc  =  inst_pcaddi;
    assign need_si26_pc  =  inst_b | inst_bl;

    assign imm = ({32{need_ui5    }} & {27'b0, rk}               ) |
                 ({32{need_si12   }} & {{20{i12[11]}}, i12}      ) |
                 ({32{need_ui12   }} & {20'b0, i12}              ) |
                 ({32{need_si14_pc}} & {{16{i14[13]}}, i14, 2'b0}) |
                 ({32{need_si16_pc}} & {{14{i16[15]}}, i16, 2'b0}) |
                 ({32{need_si20   }} & {i20, 12'b0}              ) |
                 ({32{need_si20_pc}} & {{10{i20[19]}}, i20, 2'b0}) |
                 ({32{need_si26_pc}} & {{ 4{i26[25]}}, i26, 2'b0}) ;

    // mul_div
    assign mul_div_op[ 0] = inst_mul_w;
    assign mul_div_op[ 1] = inst_mulh_w | inst_mulh_wu;
    assign mul_div_op[ 2] = inst_div_w  | inst_div_wu;
    assign mul_div_op[ 3] = inst_mod_w  | inst_mod_wu;

    assign mul_div_sign  =  inst_mul_w | inst_mulh_w | inst_div_w | inst_mod_w;

    // branch_op
    assign branch_op = {inst_beq,
                        inst_bne,
                        inst_blt,
                        inst_bge,
                        inst_bltu,
                        inst_bgeu,
                        inst_jirl,
                        inst_bl,
                        inst_b
                       };
    
    // load_op store_op
    assign load_op   = {inst_ld_b,
                        inst_ld_h,
                        inst_ld_w, 
                        inst_ld_bu, 
                        inst_ld_hu, 
                        inst_ll_w
                      };
    assign store_op  = {inst_st_b,
                        inst_st_h, 
                        inst_st_w
                       };
    assign reg_we    = ~inst_st_b    & 
                       ~inst_st_h    & 
                       ~inst_st_w    & 
                       ~inst_beq     & 
                       ~inst_bne     & 
                       ~inst_blt     & 
                       ~inst_bge     &
                       ~inst_bltu    &
                       ~inst_bgeu    &
                       ~inst_b       &
                       ~inst_syscall &
                       //~inst_tlbsrch &
                       //~inst_tlbrd   &
                       //~inst_tlbwr   &
                       //~inst_tlbfill &
                       //~inst_invtlb  &
                       //~inst_cacop   &
                       //~inst_preld   &      
                       ~inst_dbar    &      
                       ~inst_ibar    ;

    
    
    // csr
    assign csr_we    = inst_csrwr | inst_csrxchg;
    assign csr_op    = {inst_csrrd,
                        inst_csrwr,
                        inst_csrxchg,
                        inst_rdcntid_w,
                        inst_rdcntvh_w,
                        inst_rdcntvl_w,
                        inst_sc_w
                       };
    assign csr_addr  = inst[23:10];
    assign csr_wdata_sel = inst_csrxchg;
    assign csr_vec_l = {25'b0, excp_adef, excp_ipe, excp_ine, inst_break, inst_syscall, inst_ertn, csr_has_int}; 

    assign inst_valid = inst_add_w     |
                        inst_sub_w     |
                        inst_slt       |
                        inst_sltu      |
                        inst_nor       |
                        inst_and       |
                        inst_or        |
                        inst_xor       |
                        inst_sll_w     |
                        inst_srl_w     |
                        inst_sra_w     |
                        inst_mul_w     |
                        inst_mulh_w    |
                        inst_mulh_wu   |
                        inst_div_w     |
                        inst_mod_w     |
                        inst_div_wu    |
                        inst_mod_wu    |
                        inst_break     |
                        inst_syscall   |
                        inst_slli_w    |
                        inst_srli_w    |
                        inst_srai_w    |
                        //inst_idle      |
                        inst_slti      |
                        inst_sltui     |
                        inst_addi_w    |
                        inst_andi      |
                        inst_ori       |
                        inst_xori      |
                        inst_ld_b      |
                        inst_ld_h      |
                        inst_ld_w      |
                        inst_st_b      |
                        inst_st_h      |
                        inst_st_w      |
                        inst_ld_bu     |
                        inst_ld_hu     |
                        inst_ll_w      |
                        inst_sc_w      |
                        inst_jirl      |
                        inst_b         |
                        inst_bl        |
                        inst_beq       |
                        inst_bne       |
                        inst_blt       |
                        inst_bge       |
                        inst_bltu      |
                        inst_bgeu      |
                        inst_lu12i_w   |
                        inst_pcaddu12i |
                        inst_csrrd     |
                        inst_csrwr     |
                        inst_csrxchg   |
                        inst_rdcntid_w |
                        inst_rdcntvh_w |
                        inst_rdcntvl_w |
                        inst_ertn      |
                        //inst_cacop     |
                        //inst_preld     |
                        inst_dbar      |
                        inst_ibar      ;
                        //inst_tlbsrch   |
                        //inst_tlbrd     |
                        //inst_tlbwr     |
                        //inst_tlbfill   |
                        //(inst_invtlb && (rd == 5'd0 || 
                        //                 rd == 5'd1 || 
                        //                 rd == 5'd2 || 
                        //                 rd == 5'd3 || 
                        //                 rd == 5'd4 ||
                        //                 rd == 5'd5 || 
                        //                 rd == 5'd6 ));  //invtlb valid op


    assign excp_ine = ~inst_valid;

    assign kernel_inst = inst_csrrd    |
                         inst_csrwr    |
                         inst_csrxchg  |
                         //inst_cacop    |
                         //inst_tlbsrch  |
                         //inst_tlbrd    |
                         //inst_tlbwr    |
                         //inst_tlbfill  |
                         //inst_invtlb   |
                         inst_ertn     ;
                         //inst_idle     ;

    assign excp_ipe = kernel_inst && (csr_plv == 2'b11);

    // rf_res from
    // assign sel_rf_res[0] = inst_jirl | inst_bl;
    // assign sel_rf_res[1] = |load_op;
    // assign sel_rf_res[2] = |csr_op;
    // assign sel_rf_res[3] = |mul_div_op;
endmodule
