module PipeReg #(
    parameter size = 0
)
(
    input clk,
    input rst,
    input signed [size-1:0] data_i,
    output reg signed [size-1:0] data_o
);

//module PipeReg(
//    clk,
//    rst,
//    data_i,
//    data_o
//);

//parameter size = 0;
//input clk;
//input rst;
//input [size-1:0] data_i;
//output reg [size-1:0] data_o;

    always@(posedge clk, negedge rst)begin
        if(~rst)
            data_o <= 0;
        else
            data_o <= data_i;
    end

endmodule
