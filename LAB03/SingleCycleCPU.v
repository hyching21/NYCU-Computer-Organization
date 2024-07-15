module SingleCycleCPU(
    input clk,
    input start,
    output signed [31:0] r [0:31]
);
/* verilator lint_off UNUSEDSIGNAL */
/*IF*/
wire [31:0] inst, pc_i, pc_o, pc_add_o, pc_src;
wire [31:0] pc_o_id, inst_id;
/*ID*/
wire [31:0] readData1, readData2, imm;
wire branch, memRead, memWrite, ALUSrc, regWrite, zero;
wire [1:0] ALUOp, memtoReg, jump;
wire [31:0] readData1_ex, readData2_ex, imm_ex, pc_o_ex;
wire [8:0] inst_ex;
wire branch_ex, memRead_ex, memWrite_ex, ALUSrc_ex, regWrite_ex;
wire [1:0] memtoReg_ex, ALUOp_ex;
/*EX*/
wire zero_mem, branch_mem;
wire [3:0] ALUCtl;
wire [31:0] MuxALU_o, shift_o, adder_ex, ALUOut;
wire memRead_mem, memWrite_mem, regWrite_mem;
wire [1:0] memtoReg_mem;
wire [31:0] adder_mem, ALUOut_mem, readData2_mem;
wire [4:0] inst_mem;
/*MEM*/
wire [31:0] readData_o;
wire [31:0] readData_wb, ALUOut_wb;
wire memtoReg_wb, regWrite_wb;
wire [4:0] inst_wb;
/*WB*/
wire [31:0] writeData;
/* verilator lint_off UNUSEDSIGNAL */

/*IF stage*/
PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(pc_i),
    .pc_o(pc_o)
);

Adder m_Adder_1( // PC+4
    .a(pc_o),
    .b(32'd4),
    .sum(pc_add_o)
);

InstructionMemory m_InstMem(
    .readAddr(pc_o),
    .inst(inst)
);

Mux2to1 #(.size(32)) m_Mux_PC_Source(
    .sel(branch_mem & zero_mem),
    .s0(pc_add_o),
    .s1(adder_mem),
    .out(pc_src)
);

Mux2to1 #(.size(32)) Mux_PC(
    .sel(jump[0]),
    .s0(pc_src), // 00 -> other
    .s1(adder_mem), // 01 -> jal
    .out(pc_i) // pc_in
);

PipeReg #(.size(64)) IF_ID(
    .clk(clk),
    .rst(start),
    .data_i({pc_o,inst}),
    .data_o({pc_o_id,inst_id})
);
/*ID stage*/
// For Student:
// Do not change the Register instance name!
// Or you will fail validation.
Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite_wb),
    .readReg1(inst_id[19:15]),
    .readReg2(inst_id[24:20]),
    .writeReg(inst_wb),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
);

// ======= for validation =======
// == Dont change this section ==
assign r = m_Register.regs;
// ======= for vaildation =======

Control m_Control(
    .opcode(inst_id[6:0]),
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .jump(jump)
);

ImmGen m_ImmGen(
    .inst(inst_id),
    .imm(imm)
);

PipeReg #(.size(32+32+32+32+9+1+1+2+2+1+1+1)) ID_EX(
    .clk(clk),
    .rst(start),
    .data_i({pc_o_id, imm, readData1, readData2, {inst_id[30],inst_id[14:7]}, branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite}),
    .data_o({pc_o_ex, imm_ex, readData1_ex, readData2_ex, inst_ex, branch_ex, memRead_ex, memtoReg_ex, ALUOp_ex, memWrite_ex, ALUSrc_ex, regWrite_ex})
);

/*EX stage*/
ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp_ex),
    .funct7(inst_ex[8]),
    .funct3(inst_ex[7:5]),
    .ALUCtl(ALUCtl)
);

ALU m_ALU(
    .ALUctl(ALUCtl),
    .A(readData1_ex),
    .B(MuxALU_o),
    .ALUOut(ALUOut),
    .zero(zero)
);

Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(ALUSrc_ex),
    .s0(readData2_ex),
    .s1(imm_ex),
    .out(MuxALU_o)
);

ShiftLeftOne m_ShiftLeftOne(
    .i(imm_ex),
    .o(shift_o)
);

Adder m_Adder_2( // PC + imm
    .a(pc_o_ex),
    .b(shift_o),
    .sum(adder_ex)
);

PipeReg #(.size(1+1+2+1+32+32+32+5+1+1)) EX_MEM(
    .clk(clk),
    .rst(start),
    .data_i({memRead_ex, memWrite_ex, memtoReg_ex,regWrite_ex, adder_ex, ALUOut, readData2_ex, inst_ex[4:0], zero, branch_ex}),
    .data_o({memRead_mem, memWrite_mem, memtoReg_mem, regWrite_mem, adder_mem, ALUOut_mem, readData2_mem, inst_mem, zero_mem, branch_mem})
);

/*MEM stage*/
DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(memWrite_mem),
    .memRead(memRead_mem),
    .address(ALUOut_mem),
    .writeData(readData2_mem),
    .readData(readData_o)
);

PipeReg #(.size(32+32+1+5+1)) MEM_WB(
    .clk(clk),
    .rst(start),
    .data_i({readData_o, ALUOut_mem, memtoReg_mem[0],inst_mem, regWrite_mem}),
    .data_o({readData_wb, ALUOut_wb, memtoReg_wb, inst_wb, regWrite_wb})
);

/*WB stage*/
Mux2to1 #(.size(32)) m_Mux_WriteData(
    .sel(memtoReg_wb),
    .s0(ALUOut_wb),
    .s1(readData_wb),
    .out(writeData)
);

endmodule
