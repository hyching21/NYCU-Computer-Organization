module ForwardingUnit(
    input regWrite_mem,
    input regWrite_wb,
    input [4:0] idex_rs1,
    input [4:0] idex_rs2,
    input [4:0] exmem_rd,
    input [4:0] memwb_rd,
    output reg [1:0] forward_a, // for rs1
    output reg [1:0] forward_b // for rs2
);
    // 00: id/ex, 01: ex/mem, 10: mem/wb
    always @(*) begin
        // rs1
        if(regWrite_mem==1'b1 && idex_rs1==exmem_rd && exmem_rd!=5'd0)
            forward_a = 2'b01;
        else if(regWrite_wb==1'b1 && idex_rs1==memwb_rd && memwb_rd!=5'd0)
            forward_a = 2'b10;
        else
            forward_a = 2'b00;
        // rs2
        if(regWrite_mem==1'b1 && idex_rs2==exmem_rd && exmem_rd!=5'd0)
            forward_b = 2'b01;
        else if(regWrite_wb==1'b1 && idex_rs2==memwb_rd && memwb_rd!=5'd0)
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end
endmodule
