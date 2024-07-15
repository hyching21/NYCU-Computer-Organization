module Control (
    input [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite
);

    // TODO: implement your Control here
    // Hint: follow the Architecture (figure in spec) to set output signal

    always @(*) begin
        case(opcode)
            // R-type
            7'b0110011: begin
                branch = 1'b0;
                memRead = 1'b0;
                memtoReg = 1'b0;
                ALUOp = 2'b10;
                memWrite = 1'b0;
                ALUSrc = 1'b0;
                regWrite = 1'b1;
            end
            // I-type
            7'b0010011: begin
                branch = 1'b0;
                memRead = 1'b0;
                memtoReg = 1'b0;
                ALUOp = 2'b11;
                memWrite = 1'b0;
                ALUSrc = 1'b1;
                regWrite = 1'b1;
            end
            // sw
            7'b0100011: begin
                branch = 1'b0;
                memRead = 1'b0;
                memtoReg = 1'bx;
                ALUOp = 2'b00;
                memWrite = 1'b1;
                ALUSrc = 1'b1;
                regWrite = 1'b0;
            end
            // lw
            7'b0000011: begin
                branch = 1'b0;
                memRead = 1'b1;
                memtoReg = 1'b1;
                ALUOp = 2'b00;
                memWrite = 1'b0;
                ALUSrc = 1'b1;
                regWrite = 1'b1;
            end
            // beq
            7'b1100011: begin
                branch = 1'b1;
                memRead = 1'b0;
                memtoReg = 1'bx;
                ALUOp = 2'b01;
                memWrite = 1'b0;
                ALUSrc = 1'b0;
                regWrite = 1'b0;
            end
            default:begin
                branch = 1'bx;
                memRead = 1'bx;
                memtoReg = 1'bx;
                ALUOp = 2'bxx;
                memWrite = 1'bx;
                ALUSrc = 1'bx;
                regWrite = 1'bx;
            end
        endcase
    end

endmodule

