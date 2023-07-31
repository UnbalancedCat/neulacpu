module mmu (
    input  [31:0] addr_i,
    output [31:0] addr_o,
    output        cache_v
);
    
    wire [31:0] dmw0;
    assign dmw0 = 0;

    assign cache_v = (dmw0[31:29] == addr_i[31:29]);

    assign addr_o =  cache_v? {dmw0[27:25],addr_i[28:0]} : addr_i;
    
endmodule