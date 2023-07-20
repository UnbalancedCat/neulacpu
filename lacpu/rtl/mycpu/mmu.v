module mmu (
    input  [31:0] addr_i,
    output [31:0] addr_o,
    output        cache_v
);
    wire [1:0] addr_head_i, addr_head_o;
    assign addr_head_i = addr_i[31:30];

    wire kseg0_l, kseg0_h, kseg1_l, kseg1_h;
    assign kseg0_l = addr_head_i == 2'b00;
    assign kseg0_h = addr_head_i == 2'b01;
    assign kseg1_l = addr_head_i == 2'b10;
    assign kseg1_h = addr_head_i == 2'b11;
    
    wire other_seg;
    assign other_seg = ~kseg0_l & ~kseg0_h & ~kseg1_l & ~kseg1_h;
    assign addr_head_o = {2{kseg0_l}}&2'b00 | {2{kseg0_h}}&2'b01 | {2{kseg1_l}}&2'b10 | {2{kseg1_h}}&2'b11 | {2{other_seg}}&addr_head_i;
    assign addr_o = {addr_head_o, addr_i[29:0]};

    assign cache_v = ~(kseg0_l|kseg1_l|kseg1_h);
endmodule