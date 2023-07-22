module if_stage
#(
    parameter BR_BUS_WD = 33,
    parameter FS_TO_DS_BUS_WD = 65
)
(
    input         clk  ,
    input         reset,

    input         flush,
    input  [ 5:0] stall,

    input  [31:0] new_pc,
    
    input         timer_int,

    output        inst_sram_en   ,
    output [ 3:0] inst_sram_we   ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,

    input  [BR_BUS_WD       -1:0] br_bus,
    output [FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus
);
    reg         pc_valid;
    reg  [31:0] fs_pc;
    
    reg         excp_adef;
    reg  [31:0] csr_vec_h;

    wire [31:0] seq_pc;
    wire [31:0] next_pc;

    wire        br_taken;
    wire [31:0] br_target;


    assign fs_to_ds_bus = {csr_vec_h, //64:33
                           excp_adef, //32:32
                           fs_pc      //31:0
                          };

    assign {br_taken,
            br_target
        } = br_bus;

    always @ (posedge clk) begin
        if (reset) begin
            pc_valid  <= 1'b0;
            fs_pc     <= 32'h1bff_fffc;
            excp_adef <= 1'b0;
            csr_vec_h <= 32'b0;
        end
        else if (flush) begin
            pc_valid <= 1'b1;
            fs_pc     <= new_pc;
            excp_adef <= |new_pc[1:0];
            csr_vec_h <= 32'b0;
        end
        else if (!stall[0]) begin
            pc_valid  <= 1'b1;
            fs_pc     <= next_pc;
            excp_adef <= |next_pc[1:0];
            csr_vec_h <= 0; // timer_int; TODO!
        end
    end

    assign seq_pc  = fs_pc + 3'h4;
    assign next_pc = br_taken ? br_target : seq_pc;


    assign inst_sram_en     = (/*flush |*/ br_taken) ? 1'b0 : pc_valid;
    assign inst_sram_we     = 4'h0;
    assign inst_sram_addr   = fs_pc;
    assign inst_sram_wdata  = 32'b0;
endmodule