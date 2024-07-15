module HazardDetection(
    input memRead, //idex_memRead
    input [4:0] idex_rd,
    input [4:0] ifid_rs1,
    input [4:0] ifid_rs2,
    output reg ifid_write,
    output reg pc_write,
    output reg stall
);

    always @(*) begin
        pc_write = 1'b1;
        ifid_write = 1'b1;
        stall = 1'b0;
        if(memRead && (idex_rd==ifid_rs1 || idex_rd==ifid_rs2)) begin
            pc_write = 1'b0;
            ifid_write = 1'b0;
            stall = 1'b1;
        end
    end

endmodule

