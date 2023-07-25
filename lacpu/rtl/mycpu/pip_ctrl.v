`define StallBus 6
module pip_ctrl(
    input  reset,
    input  except_en,
    input  stallreq_fs_for_cache,
    input  stallreq_es_for_cache,
    input  stallreq_ds,
    input  stallreq_es,
    input  stallreq_axi,
    input  stallreq_cache,
    output reg flush,
    output reg [`StallBus-1:0] stall
);
    //stall[0] --?
    //stall[1] --?
    //stall[2] --id
    //stall[3]
    //stall[4]
    //stall[5]
    always @ (*) begin
        if (reset) begin
            flush = 0;
            stall = `StallBus'b000000;
        end
        else if (stallreq_axi) begin
            flush = 0;
            stall = `StallBus'b111111;
        end
        else if (except_en) begin
            flush = 1;
            stall = `StallBus'b0;
        end
        //id段发生暂停，此时id及之前暂停
        else if (stallreq_ds) begin
            flush = 0;
            stall = `StallBus'b000111;
        end
        else if (stallreq_es) begin
            flush = 0;
            stall = `StallBus'b111111;
        end
        // else if(stallreq_fs_for_cache) begin
        //     flush = 0;
        //     stall = `StallBus'b000011;
        // end
        // else if(stallreq_es_for_cache) begin
        //     flush = 0;
        //     stall = `StallBus'b011111;
        // end
        // else if(stallreq_cache) begin
        //     flush = 0;
        //     stall = `StallBus'b111111;
        // end
        else begin
            flush = 0;
            stall = `StallBus'b000000;
        end
    end
endmodule
