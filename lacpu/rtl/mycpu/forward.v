module forward
#(
    parameter DEST_WD   = 5,
    parameter RESULT_WD = 32,
    parameter CTRL_WD   = 2
)
(
    input         clk  ,
    input         reset,

    input         flush,
    input  [ 5:0] stall,

    input  [ 4:0] rj,
    input  [ 4:0] rkd,
    input                   es_reg_we ,
    input  [DEST_WD   -1:0] es_dest   ,
    input  [RESULT_WD -1:0] es_result ,
    input  [CTRL_WD   -1:0] es_ctrl   ,
    input                   dts_reg_we,
    input  [DEST_WD   -1:0] dts_dest  ,
    input  [RESULT_WD -1:0] dts_result,
    input  [CTRL_WD   -1:0] dts_ctrl  ,
    input                   ms1_reg_we,
    input  [DEST_WD   -1:0] ms1_dest  ,
    input  [RESULT_WD -1:0] ms1_result,
    input  [CTRL_WD   -1:0] ms1_ctrl  ,
    input                   ms2_reg_we,
    input  [DEST_WD   -1:0] ms2_dest  ,
    input  [RESULT_WD -1:0] ms2_result,
    input  [CTRL_WD   -1:0] ms2_ctrl  ,

    output reg                  src1_is_forward,
    output reg                  src2_is_forward,

    output reg [RESULT_WD -1:0] src1_forward_result,
    output reg [RESULT_WD -1:0] src2_forward_result,

    output                      stallreq_forward
);

    wire src1_is_es_result;
    wire src1_is_dts_result;
    wire src1_is_ms1_result;
    wire src1_is_ms2_result;

    wire src2_is_es_result;
    wire src2_is_dts_result;
    wire src2_is_ms1_result;
    wire src2_is_ms2_result;

    wire src1_is_forward_w;
    wire src2_is_forward_w;

    wire [RESULT_WD -1:0] src1_forward_result_w;
    wire [RESULT_WD -1:0] src2_forward_result_w;

    assign src1_is_es_result  = es_reg_we  & (rj  == es_dest ) & (rj  != 0);
    assign src1_is_dts_result = dts_reg_we & (rj  == dts_dest) & (rj  != 0);
    assign src1_is_ms1_result = ms1_reg_we & (rj  == ms1_dest) & (rj  != 0);
    assign src1_is_ms2_result = ms2_reg_we & (rj  == ms2_dest) & (rj  != 0);

    assign src2_is_es_result  = es_reg_we  & (rkd == es_dest ) & (rkd != 0);
    assign src2_is_dts_result = dts_reg_we & (rkd == dts_dest) & (rkd != 0);
    assign src2_is_ms1_result = ms1_reg_we & (rkd == ms1_dest) & (rkd != 0);
    assign src2_is_ms2_result = ms2_reg_we & (rkd == ms2_dest) & (rkd != 0);

    assign src1_is_forward_w = src1_is_es_result | src1_is_dts_result | src1_is_ms1_result | src1_is_ms2_result;
    assign src2_is_forward_w = src2_is_es_result | src2_is_dts_result | src2_is_ms1_result | src2_is_ms2_result;

    assign src1_forward_result_w = src1_is_es_result  ? es_result  :
                                   src1_is_dts_result ? dts_result :
                                   src1_is_ms1_result ? ms1_result :
                                   src1_is_ms2_result ? ms2_result :
                                                        32'b0;
    
    assign src2_forward_result_w = src2_is_es_result  ? es_result  :
                                   src2_is_dts_result ? dts_result :
                                   src2_is_ms1_result ? ms1_result :
                                   src2_is_ms2_result ? ms2_result :
                                                        32'b0;

    assign stallreq_forward = ((|es_ctrl ) & (src1_is_es_result  | src2_is_es_result ))
                            | ((|dts_ctrl) & (src1_is_dts_result | src2_is_dts_result))
                            | ((|ms1_ctrl) & (src1_is_ms1_result | src2_is_ms1_result));
                            //| ((|ms2_ctrl) & (src1_is_ms2_result | src2_is_ms2_result));

    always @(posedge clk) begin
        if (reset) begin
            src1_is_forward     <= 0;
            src2_is_forward     <= 0;
            src1_forward_result <= 0;
            src2_forward_result <= 0;
        end
        else if (stall[2] & (!stall[3])) begin
            src1_is_forward     <= 0;
            src2_is_forward     <= 0;
            src1_forward_result <= 0;
            src2_forward_result <= 0;
        end
        else if (!stall[2]) begin
            src1_is_forward     <= src1_is_forward_w;
            src2_is_forward     <= src2_is_forward_w;
            src1_forward_result <= src1_forward_result_w;
            src2_forward_result <= src2_forward_result_w;
        end
    end

endmodule