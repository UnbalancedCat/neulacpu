module bru(
    input  [31:0] pc,
    input  [31:0] rj_value,
    input  [31:0] rkd_value,
    input  [31:0] imm,

    input  [ 8:0] branch_op,

    output        br_taken,
    output [31:0] br_target
);

    wire inst_jirl;   
    wire inst_b;      
    wire inst_bl;     
    wire inst_beq;    
    wire inst_bne; 
    wire inst_blt;
    wire inst_bge;
    wire inst_bltu;
    wire inst_bgeu;

    wire rj_eq_rd;
    wire rj_lt_rd;
    wire rj_ltu_rd;

    assign {inst_beq,
            inst_bne,
            inst_blt,
            inst_bge,
            inst_bltu,
            inst_bgeu,
            inst_jirl,
            inst_bl,
            inst_b
           } = branch_op;

    assign rj_eq_rd  = (rj_value == rkd_value);
    assign rj_ltu_rd = (rj_value <  rkd_value);
    assign rj_lt_rd  = (rj_value[31] && ~rkd_value[31]) ? 1'b1 :
                       (~rj_value[31] && rkd_value[31]) ? 1'b0 :
                                                          rj_ltu_rd;
    assign br_taken  = (   inst_beq  &&  rj_eq_rd
                        || inst_bne  && !rj_eq_rd
                        || inst_blt  &&  rj_lt_rd
                        || inst_bge  && !rj_lt_rd
                        || inst_bltu &&  rj_ltu_rd
                        || inst_bgeu && !rj_ltu_rd
                        || inst_jirl
                        || inst_bl
                        || inst_b
                        );
    
    assign br_target = ({32{inst_beq|inst_bne|inst_bl|inst_b|inst_blt|inst_bge|inst_bltu|inst_bgeu}} & (pc + imm))
                     | ({32{inst_jirl}}                                                              & (rj_value + imm));
endmodule