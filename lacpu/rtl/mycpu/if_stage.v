module if1_stage
#(
    parameter BR_BUS_WD = 33,
    parameter FS_TO_DS_BUS_WD = 34
)
(
    input         clk  ,
    input         reset,

    input         flush,
    input  [ 5:0] stall,

    input  [31:0] new_pc,

    // output        inst_sram_en   ,
    // output [ 3:0] inst_sram_we   ,
    // output [31:0] inst_sram_addr ,
    // output [31:0] inst_sram_wdata,

    input  [BR_BUS_WD       -1:0] br_bus,
    output [FS_TO_DS_BUS_WD -1:0] fs1_to_fs2_bus
);
    reg         pc_valid;
    reg  [31:0] fs_pc;
    
    reg         excp_adef;

    wire [31:0] seq_pc;
    wire [31:0] next_pc;

    wire        br_taken;
    wire [31:0] br_target;


    assign fs1_to_fs2_bus = {(br_taken ? 1'b0 : pc_valid),  //33:33
                             excp_adef,                     //32:32
                             fs_pc                          //31:0
                            };

    assign {br_taken,
            br_target
        } = br_bus;

    always @ (posedge clk) begin
        if (reset) begin
            pc_valid  <= 1'b0;
            fs_pc     <= 32'h1bff_fffc;
            excp_adef <= 1'b0;
        end
        else if (flush) begin
            pc_valid <= 1'b1;
            fs_pc     <= new_pc;
            excp_adef <= |new_pc[1:0];
        end
        else if (!stall[0]) begin
            pc_valid  <= 1'b1;
            fs_pc     <= next_pc;
            excp_adef <= |next_pc[1:0];
        end
    end

    assign seq_pc  = fs_pc + 3'h4;
    assign next_pc = br_taken ? br_target : seq_pc;

    // assign inst_sram_en     = br_taken ? 1'b0 : pc_valid;
    // assign inst_sram_we     = 4'h0;
    // assign inst_sram_addr   = fs_pc;
    // assign inst_sram_wdata  = 32'b0;
endmodule

module if2_stage
#(
    parameter FS_TO_DS_BUS_WD = 34
)
(
    input         clk  ,
    input         reset,

    input         flush,
    input  [ 5:0] stall,

    input         br_taken,
    input  [FS_TO_DS_BUS_WD -1:0] fs1_to_fs2_bus,

    output [FS_TO_DS_BUS_WD -1:0] fs2_to_fs3_bus,

    output        inst_sram_en   ,
    output [ 3:0] inst_sram_we   ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata
);
    reg  [FS_TO_DS_BUS_WD -1:0] fs1_to_fs2_bus_r;
    
    wire        br_flush;
    wire [31:0] fs_pc;
    wire        pc_valid;

    assign br_flush = br_taken;
    assign fs_pc    = fs1_to_fs2_bus_r[31:0];
    assign pc_valid = fs1_to_fs2_bus_r[33];

    assign fs2_to_fs3_bus = fs1_to_fs2_bus_r;

    always @ (posedge clk) begin
        if (reset) begin
            fs1_to_fs2_bus_r <= 0;
        end
        else if (flush | br_flush) begin
            fs1_to_fs2_bus_r <= 0;
        end
        else if (stall[0] & !stall[1]) begin
            fs1_to_fs2_bus_r <= 0;
        end
        else if (!stall[0]) begin
            fs1_to_fs2_bus_r <= fs1_to_fs2_bus;
        end
    end

    assign inst_sram_en     = br_taken ? 1'b0 : pc_valid;
    assign inst_sram_we     = 4'h0;
    assign inst_sram_addr   = fs_pc;
    assign inst_sram_wdata  = 32'b0;

endmodule

module if3_stage
#(
    parameter FS_TO_DS_BUS_WD = 34
)
(
    input         clk  ,
    input         reset,

    input         flush,
    input  [ 5:0] stall,

    input         br_taken,
    input  [FS_TO_DS_BUS_WD -1:0] fs2_to_fs3_bus,

    output [FS_TO_DS_BUS_WD -1:0] fs3_to_ds_bus
);
    reg  [FS_TO_DS_BUS_WD -1:0] fs2_to_fs3_bus_r;
    
    wire br_flush;

    assign br_flush = br_taken;

    assign fs3_to_ds_bus = fs2_to_fs3_bus_r;

    always @ (posedge clk) begin
        if (reset) begin
            fs2_to_fs3_bus_r <= 0;
        end
        else if (flush | br_flush) begin
            fs2_to_fs3_bus_r <= 0;
        end
        else if (stall[0] & !stall[1]) begin
            fs2_to_fs3_bus_r <= 0;
        end
        else if (!stall[0]) begin
            fs2_to_fs3_bus_r <= fs2_to_fs3_bus;
        end
    end
endmodule