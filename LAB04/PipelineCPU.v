module PipelineCPU(
    input clk,
    input start,
    output signed [31:0] r [0:31]
);
/* verilator lint_off UNUSEDSIGNAL */
/*IF*/
wire [31:0] inst, pc_i, pc_o, pc_add_o, pc_src;
/*ID*/
wire ifid_write, pc_write, stall;
wire [31:0] pc_o_id,inst_id, readData1, readData2, imm, shift_o;
wire branch, memRead, memWrite, ALUSrc, regWrite, branch_taken;
wire [1:0] memtoReg, ALUOp, jump;
wire [8:0] control;
/*EX*/
wire [8:0] control_ex;
wire [31:0] pc_o_ex,readData1_ex,readData2_ex,imm_ex, MuxALU_o1, MuxALU_o2, MuxALU_o, ALUOut, adder_ex, adder_o3;
wire [4:0] inst_rs1,inst_rs2,inst_rd;
wire [3:0] inst_func, ALUCtl;
wire [1:0] forward_a, forward_b, jump_ex;
wire if_flush, id_flush, zero; // keep it or not??
/*MEM*/
wire [31:0] pc_o_mem, ALUOut_mem, MuxALU_o2_mem, readData_o;
wire [4:0] inst_rd_mem;
wire [1:0] memtoReg_mem;
wire memRead_mem, memWrite_mem, regWrite_mem;
/*WB*/
wire [31:0] pc_o_wb,pc_add_wb, readData_wb, ALUOut_wb, writeData;
wire [4:0] inst_rd_wb;
wire [1:0] memtoReg_wb;
wire regWrite_wb;
/* verilator lint_off UNUSEDSIGNAL */
/*-------------------------------------------------------------*/
/*IF stage*/
Mux2to1 #(.size(32)) m_Mux_PC_Source(
        .sel(control_ex[8] & branch_taken),
        .s0(pc_add_o),
        .s1(adder_ex),
        .out(pc_src)
);

Mux3to1 #(.size(32)) Mux_PC(
        .sel(jump_ex),
        .s0(pc_src), // 00 -> other
        .s1(adder_ex), // 01 -> jal
        .s2(adder_o3), // 10 -> jalr
        .out(pc_i) // pc_in
);

PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_write(pc_write),
    .pc_i(pc_i),
    .pc_o(pc_o)
);

Adder m_Adder_PC( // PC+4
    .a(pc_o),
    .b(32'd4),
    .sum(pc_add_o)
);

InstructionMemory m_InstMem(
    .readAddr(pc_o),
    .inst(inst)
);

PipeReg #(.size(64)) IF_ID(
    .clk(clk),
    .rst(start),
    .flush(if_flush),
    .write(ifid_write),
    .data_i({pc_o,inst}),
    .data_o({pc_o_id,inst_id})
);

/*ID stage*/
HazardDetection m_HD(
    .memRead(control_ex[7]),
    .idex_rd(inst_rd),
    .ifid_rs1(inst_id[19:15]),
    .ifid_rs2(inst_id[24:20]),
    .ifid_write(ifid_write),
    .pc_write(pc_write),
    .stall(stall)
);
// For Student:
// Do not change the Register instance name!
// Or you will fail validation.
Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite_wb),
    .readReg1(inst_id[19:15]),
    .readReg2(inst_id[24:20]),
    .writeReg(inst_rd_wb),
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

Mux2to1 #(.size(9)) Mux_control(
    .sel(stall),
    .s0({branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite}),
    //[8] [7] [6:5] [4:3] [2] [1] [0]
    .s1(9'd0),
    .out(control)
);
ImmGen m_ImmGen(
    .inst(inst_id),
    .imm(imm)
);

PipeReg #(.size(32+2+9+32+32+32+5+5+5+4)) ID_EX(
    .clk(clk),
    .rst(start),
    .flush(id_flush),
    .write(1'b1),
    .data_i({pc_o_id, jump, control,readData1,readData2,imm,inst_id[19:15],inst_id[24:20],inst_id[11:7],{inst_id[30],inst_id[14:12]}}),
    .data_o({pc_o_ex, jump_ex, control_ex,readData1_ex,readData2_ex,imm_ex,inst_rs1,inst_rs2,inst_rd,inst_func})

);

/*EX stage*/
ALUCtrl m_ALUCtrl(
    .ALUOp(control_ex[4:3]),
    .funct7(inst_func[3]),
    .funct3(inst_func[2:0]),
    .ALUCtl(ALUCtl)
);

ForwardingUnit m_ForwardingUnit(
    .regWrite_mem(regWrite_mem),
    .regWrite_wb(regWrite_wb),
    .idex_rs1(inst_rs1),
    .idex_rs2(inst_rs2),
    .exmem_rd(inst_rd_mem),
    .memwb_rd(inst_rd_wb),
    .forward_a(forward_a), // for rs1
    .forward_b(forward_b) // for rs2
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

Adder m_Adder_3( // reg[rs1] + imm
    .a(MuxALU_o1),
    .b(imm_ex),
    .sum(adder_o3)
);

Comparator m_Comparator(
    .rs1_data(MuxALU_o1),
    .rs2_data(MuxALU_o2),
    .funct3(inst_func[2:0]),
    .branch_taken(branch_taken)
);

Flush m_Flush(
    .branch_taken(branch_taken),
    .branch(control_ex[8]),
    .jump(jump_ex),
    .if_flush(if_flush),
    .id_flush(id_flush)
);

Mux3to1 #(.size(32)) m_Mux_for1(
    .sel(forward_a),
    .s0(readData1_ex),
    .s1(ALUOut_mem),
    .s2(writeData),
    .out(MuxALU_o1)
);

Mux3to1 #(.size(32)) m_Mux_for2(
    .sel(forward_b),
    .s0(readData2_ex),
    .s1(ALUOut_mem),
    .s2(writeData),
    .out(MuxALU_o2)
);


Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(control_ex[1]),
    .s0(MuxALU_o2),
    .s1(imm_ex),
    .out(MuxALU_o)
);

ALU m_ALU(
    .ALUctl(ALUCtl),
    .A(MuxALU_o1),
    .B(MuxALU_o),
    .ALUOut(ALUOut),
    .zero(zero) //zero -> take the branch or not?
);


PipeReg #(.size(32+32+32+5+5)) EX_MEM(
    .clk(clk),
    .rst(start),
    .flush(1'b0),
    .write(1'b1),
    .data_i({pc_o_ex,ALUOut,MuxALU_o2,inst_rd,control_ex[7],control_ex[6:5],control_ex[2],control_ex[0]}),
    .data_o({pc_o_mem,ALUOut_mem,MuxALU_o2_mem,inst_rd_mem, memRead_mem, memtoReg_mem, memWrite_mem, regWrite_mem})
);

/* MEM stage*/
DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(memWrite_mem),
    .memRead(memRead_mem),
    .address(ALUOut_mem),
    .writeData(MuxALU_o2_mem),
    .readData(readData_o)
);

PipeReg #(.size(32+32+32+5+2+1)) MEM_WB(
    .clk(clk),
    .rst(start),
    .flush(1'b0),
    .write(1'b1),
    .data_i({pc_o_mem,readData_o, ALUOut_mem, inst_rd_mem, memtoReg_mem, regWrite_mem}),
    .data_o({pc_o_wb,readData_wb, ALUOut_wb, inst_rd_wb, memtoReg_wb, regWrite_wb})
);

/* WB stage*/
Adder m_Adder_WB( // PC+4
    .a(pc_o_wb),
    .b(32'd4),
    .sum(pc_add_wb)
);

Mux3to1 #(.size(32)) Mux_WB(
    .sel(memtoReg_wb),
    .s0(ALUOut_wb),
    .s1(readData_wb),
    .s2(pc_add_wb), // PC+4
    .out(writeData)
);

endmodule
