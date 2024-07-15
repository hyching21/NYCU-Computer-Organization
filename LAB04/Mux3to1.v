module Mux3to1 #(
    parameter size = 32
)
(
    input [1:0]sel,
    input signed [size-1:0] s0,
    input signed [size-1:0] s1,
    input signed [size-1:0] s2,
    output signed [size-1:0] out
);
    // TODO: implement your 3to1 multiplexer here
    reg [size-1:0] data_o;
    always @(sel or s0 or s1 or s2) begin
        case(sel)
            2'b00: data_o = s0;
            2'b01: data_o = s1;
            2'b10: data_o = s2;
            default: data_o = 0;
        endcase
    end
    assign out = data_o;
endmodule
