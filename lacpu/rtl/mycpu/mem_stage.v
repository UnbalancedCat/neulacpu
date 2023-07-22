module mem_stage
#(
    parameter ES_TO_MS_BUS_WD = 271,
    parameter MS_TO_ES_BUS_WD = 38,
    parameter MS_TO_WS_BUS_WD = 102
)
(
    input         clk,
    input         reset,
    input         flush,
    input  [ 5:0] stall,

    output        except_en,
    output [31:0] new_pc,

    output [ 1:0] csr_plv,
    output        csr_has_int,

    input         stallreq_axi,

    input  [ 7:0] ext_int,

    input  [ES_TO_MS_BUS_WD -1:0] es_to_ms_bus,
    output [MS_TO_ES_BUS_WD -1:0] ms_to_es_bus,
    output [MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus,

    input  [31:0] data_sram_rdata
);

    reg  [ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
    reg  [31:0] data_sram_rdata_r;
    reg  [31:0] csr_rdata_r;
    reg         stall_flag;

    wire [63:0] csr_vec;
    wire [63:0] csr_bus;
    wire [ 5:0] load_op;
    wire [ 2:0] store_op;
    wire        reg_we;
    wire [ 4:0] dest;
    wire [31:0] es_result;
    wire [31:0] ms_pc;
    wire [31:0] inst;

    wire [31:0] data_temp;
    wire [31:0] csr_result;
    wire [31:0] csr_rdata;

    wire inst_ll_w;
    wire inst_ld_b;
    wire inst_ld_bu;
    wire inst_ld_h;
    wire inst_ld_hu;
    wire inst_ld_w;

    wire [ 3:0] byte_sel;
    wire [31:0] ms_result;

    wire        csr_we;
    wire        csr_wdata_sel;
    wire [ 6:0] csr_op;
    wire [13:0] csr_addr;
    wire [31:0] csr_wdata;


    wire [31:0] src1;

    wire [31:0] ms_final_result;

    assign {csr_vec  ,//270:207
            csr_bus  ,//206:143
            load_op  ,//142:137
            store_op ,//136:134
            reg_we   ,//133:133
            dest     ,//132:128
            es_result,//127:96
            src1     ,//95 :64
            ms_pc    ,//63 :32
            inst      //31 :0
           } = es_to_ms_bus_r;

    assign ms_to_es_bus = {reg_we,
                           dest,
                           es_result
                          };

    assign ms_to_ws_bus = {reg_we           ,//101:101
                           dest             ,//100:96
                           ms_final_result  ,//95 :64
                           ms_pc            ,//63 :32
                           inst              //31 :0
                          };

    always @ (posedge clk) begin
        if (reset) begin
            es_to_ms_bus_r <= 0;
        end
        else if (flush) begin
            es_to_ms_bus_r <= 0;
        end
        else if (stall[3]&(!stall[4])) begin
            es_to_ms_bus_r <= 0;
        end
        else if (!stall[3]) begin
            es_to_ms_bus_r <= es_to_ms_bus;
        end
    end
    
    always @ (posedge clk) begin
        if (reset) begin
            data_sram_rdata_r <= 0;
            csr_rdata_r <= 0;
            stall_flag <= 1'b0;
        end
        else if (flush) begin
            data_sram_rdata_r <= 0;
            csr_rdata_r <= 0;
            stall_flag <= 1'b0;
        end
        else if (!stall[3]) begin
            data_sram_rdata_r <= data_sram_rdata;
            csr_rdata_r <= csr_rdata;
            stall_flag <= 1'b0;
        end
        else if (stall_flag) begin
            
        end
        else if (stall[3]&stall[4])begin
            data_sram_rdata_r <= data_sram_rdata;
            csr_rdata_r <= csr_rdata;
            stall_flag <= 1'b1;
        end
    end

    assign data_temp  = stall_flag ? data_sram_rdata_r : data_sram_rdata;
    assign csr_result = stall_flag ? csr_rdata_r : csr_rdata;

    assign {inst_ld_b,
            inst_ld_h,
            inst_ld_w, 
            inst_ld_bu, 
            inst_ld_hu, 
            inst_ll_w
           } = load_op;

    decoder_2_4 u_decoder_2_4(
        .in (es_result[1:0]),
        .out(byte_sel      )
    );

    assign ms_result = (inst_ld_b  & byte_sel[0]) ? {{24{data_temp[ 7]}}, data_temp[ 7: 0]} :
                       (inst_ld_b  & byte_sel[1]) ? {{24{data_temp[15]}}, data_temp[15: 8]} :
                       (inst_ld_b  & byte_sel[2]) ? {{24{data_temp[23]}}, data_temp[23:16]} :
                       (inst_ld_b  & byte_sel[3]) ? {{24{data_temp[31]}}, data_temp[31:24]} :
                       (inst_ld_bu & byte_sel[0]) ? { 24'b0, data_temp[ 7: 0]}              :
                       (inst_ld_bu & byte_sel[1]) ? { 24'b0, data_temp[15: 8]}              :
                       (inst_ld_bu & byte_sel[2]) ? { 24'b0, data_temp[23:16]}              :
                       (inst_ld_bu & byte_sel[3]) ? { 24'b0, data_temp[31:24]}              :
                       (inst_ld_h  & byte_sel[0]) ? {{16{data_temp[15]}}, data_temp[15: 0]} :
                       (inst_ld_h  & byte_sel[2]) ? {{16{data_temp[31]}}, data_temp[31:16]} :
                       (inst_ld_hu & byte_sel[0]) ? { 16'b0, data_temp[15: 0]}              :
                       (inst_ld_hu & byte_sel[2]) ? { 16'b0, data_temp[31:16]}              :
                       (inst_ld_w  & byte_sel[0]) ?   data_temp                             :
                                                      32'b0; // inst_ll ? 

    assign {csr_we,
            csr_wdata_sel,
            csr_op,
            csr_addr,
            csr_wdata
           } = csr_bus;

    csr u_csr(
        .clk            (clk               ),
        .reset          (reset             ),
        .stall          (stall[3]&stall[4] ),
        .pc             (ms_pc             ),
        .src1           (src1              ),
        .error_va       (es_result         ),
        .plv_out        (csr_plv           ),
        .has_int_out    (csr_has_int       ),
        .csr_we         (csr_we            ),
        .csr_vec        (csr_vec           ),
        .csr_op         (csr_op            ),
        .csr_addr       (csr_addr          ),
        .csr_wdata_sel  (csr_wdata_sel     ),
        .csr_wdata      (csr_wdata         ),
        .csr_rdata      (csr_rdata         ),
        .except_en      (except_en         ),
        .new_pc         (new_pc            ),
        .stallreq_axi   (stallreq_axi      ),
        .ext_int        (ext_int           )
    );
    
    assign ms_final_result = (|load_op)  ? ms_result  :
                             (|csr_op )  ? csr_result :
                                           es_result;

endmodule