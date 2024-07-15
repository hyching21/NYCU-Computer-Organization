module PipeReg #(
    parameter size = 0
)
(
    input clk,
    input rst,
    input flush,
    input write,
    input signed [size-1:0] data_i,
    output reg signed [size-1:0] data_o
);

    always@(posedge clk, negedge rst)begin
        if(~rst)
            data_o <= 0;
        else
            if(flush)
                data_o <= 0;
            else begin
                if(write)
                    data_o <= data_i;
                else
                    data_o <= data_o;
            end

    end

endmodule
