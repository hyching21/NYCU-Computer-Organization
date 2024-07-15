module SingleCycleCPU (
    input clk,
    input start,
    output signed [31:0] r [0:31]
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

// TODO: connect wire to realize SingleCycleCPU
// The following provides simple template,
// you can modify it as you wish except I/O pin and register module

wire [31:0]  pc_o, adder_o, inst, writeData, readData1, readData2, imm, shift_o, adder_o2, MuxPC_o, MuxALU_o, ALUOut, readData, adder_o3, pc_src;
wire branch, memRead, memWrite, ALUSrc, regWrite, and_o , zero;
wire [3:0] ALUCtl;
wire [1:0] ALUOp, memtoReg, jump;

PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(MuxPC_o),
    .pc_o(pc_o)
);

Adder m_Adder_1( // PC+4
    .a(pc_o),
    .b(32'd4),
    .sum(adder_o)
);

InstructionMemory m_InstMem(
    .readAddr(pc_o),
    .inst(inst)
);

Control m_Control(
    .opcode(inst[6:0]),
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .jump(jump)
);

// For Student:
// Do not change the Register instance name!
// Or you will fail validation.

Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite),
    .readReg1(inst[19:15]),
    .readReg2(inst[24:20]),
    .writeReg(inst[11:7]),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
);

// ======= for validation =======
// == Dont change this section ==
assign r = m_Register.regs;
// ======= for vaildation =======

ImmGen m_ImmGen(
    .inst(inst),
    .imm(imm)
);

ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(shift_o)
);

Adder m_Adder_2( // PC + imm
    .a(pc_o),
    .b(shift_o),
    .sum(adder_o2)
);

Adder m_Adder_3( // reg[rs1] + imm
    .a(readData1),
    .b(imm),
    .sum(adder_o3)
);

and A1(and_o, branch, zero);


Mux2to1 #(.size(32)) m_Mux_PC_Source(
        .sel(and_o),
        .s0(adder_o),
        .s1(adder_o2),
        .out(pc_src)
);

Mux3to1 #(.size(32)) Mux_PC(
        .sel(jump),
        .s0(pc_src), // 00 -> other
        .s1(adder_o2), // 01 -> jal
        .s2(adder_o3), // 10 -> jalr
        .out(MuxPC_o) // pc_in
);


Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(ALUSrc),
    .s0(readData2),
    .s1(imm),
    .out(MuxALU_o)
);

ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp),
    .funct7(inst[30]),
    .funct3(inst[14:12]),
    .ALUCtl(ALUCtl)
);

ALU m_ALU(
    .ALUctl(ALUCtl),
    .A(readData1),
    .B(MuxALU_o),
    .ALUOut(ALUOut),
    .zero(zero)
);

DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(memWrite),
    .memRead(memRead),
    .address(ALUOut),
    .writeData(readData2),
    .readData(readData)
);

Mux3to1 #(.size(32)) m_Mux_WriteData( // write to reg[rd]
    .sel(memtoReg),
    .s0(ALUOut), // ALU
    .s1(readData), // rd
    .s2(adder_o), // PC+4
    .out(writeData)
);

endmodule
