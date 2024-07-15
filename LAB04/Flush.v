module Flush (
    input branch_taken,
    input branch,
    input [1:0] jump,
    output reg if_flush,
    output reg id_flush
);
    always @(*) begin
        case(jump)
            2'b00: begin
                if (branch & branch_taken) begin
                    if_flush = 1'b1;
                    id_flush = 1'b1;
                end else begin
                    if_flush = 1'b0;
                    id_flush = 1'b0;
                end
            end
            2'b01: begin // jal
                if_flush = 1'b1;
                id_flush = 1'b1;
            end
            2'b10: begin // jalr
                if_flush = 1'b1;
                id_flush = 1'b1;
            end
            default: begin
                if_flush = 1'b0;
                id_flush = 1'b0;
            end
        endcase
    end
endmodule
