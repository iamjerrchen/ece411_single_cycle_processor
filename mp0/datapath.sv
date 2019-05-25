import rv32i_types::*;

module datapath
(
    /* input port */
    input clk,
    input rv32i_word mem_rdata,

    /* from Control */
	 input load_pc,
	 input load_ir,
	 input load_regfile,
    input load_mar,
	 input load_mdr,
	 input load_data_out,
	 
    input pcmux_sel,
	 input alumux1_sel,
	 input [2:0] alumux2_sel,
	 input [1:0] regfilemux_sel,
	 input marmux_sel,
	 input cmpmux_sel,
	 
	 input alu_ops aluop,
	 input branch_funct3_t cmpop,

    /* to Control */
	 output rv32i_reg rs1,
	 output rv32i_reg rs2,
    output rv32i_opcode opcode, // origin: IR
	 output logic [2:0] funct3, // origin: IR
	 output logic [6:0] funct7, // origin: IR
	 output logic br_en,
	 
	 /* to Memory */
    output rv32i_word mem_address, //origin: MAR
	 output rv32i_word mem_wdata // origin: mem_data_out
);

/* declare internal signals - intl internal */
rv32i_reg rd; // origin: IR
rv32i_word i_imm, u_imm, b_imm, s_imm; // origin: IR
rv32i_word j_imm; // mp1

rv32i_word pc_out; // origin: PC
rv32i_word pcmux_out; // origin: pcmux
rv32i_word pc_plus4_out; // origin: pc_plus4

rv32i_word alu_out; // origin: ALU
rv32i_word alumux1_out, alumux2_out; // origin: alumux

rv32i_word rs1_out, rs2_out; // origin: regfile
rv32i_word regfilemux_out; // origin: regfilemux

rv32i_word marmux_out; // origin: marmux

rv32i_word zext_br_en;
rv32i_word cmpmux_out; // origin: cmpmux

rv32i_word mdrreg_out; // origin: MDR

/*
 * IR
 */
ir IR
(
	.clk(clk),
	.load(load_ir),
	.in(mdrreg_out),
	// out
	.funct3(funct3),
	.funct7(funct7),
	.opcode(opcode),
	.i_imm(i_imm),
	.s_imm(s_imm),
	.b_imm(b_imm),
	.u_imm(u_imm),
	.j_imm(j_imm),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd)
);

/*
 * regfile
 */
regfile regfile
(
	.clk(clk),
	.load(load_regfile),
	.in(regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	// out
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

mux4 regfilemux
(
	.sel(regfilemux_sel),
	.a(alu_out),
	.b(zext_br_en),
	.c(u_imm),
	.d(mdrreg_out),
	// out
	.f(regfilemux_out)
);

/*
 * ALU
 */
alu alu_unit
(
	.aluop(aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	// out
	.f(alu_out)
);

mux2 alumux1
(
	.sel(alumux1_sel),
	.a(rs1_out),
	.b(pc_out),
	// out
	.f(alumux1_out)
);

mux8 alumux2
(
	.sel(alumux2_sel),
	.a(i_imm),
	.b(u_imm),
	.c(b_imm),
	.d(s_imm),
	.e(rs2_out),
	// out
	.i(alumux2_out)
);

/*
 * MAR
 */
register mar
(
   .clk(clk),
   .load(load_mar),
   .in(marmux_out),
   .out(mem_address)
);

mux2 marmux
(
	.sel(marmux_sel),
	.a(pc_out),
	.b(alu_out),
	// out
	.f(marmux_out)
);

/*
 * MDR
 */
register mdr
(
	.clk(clk),
	.load(load_mdr),
	.in(mem_rdata),
	.out(mdrreg_out)
);

/*
 * mem_data_out
 */
register mem_data_out
(
	.clk(clk),
	.load(load_data_out),
	.in(rs2_out),
	.out(mem_wdata)
);
 
/*
 * CMP
 */
cmp cmp_unit // zext output
(
	.cmpop(cmpop),
	.op1(rs1_out),
	.op2(cmpmux_out),
	.br_en(br_en)
);

zext_1b zext
(
	.in(br_en),
	.out(zext_br_en)
);

mux2 #(.width(32)) cmpmux
(
	.sel(cmpmux_sel),
	.a(rs2_out),
	.b(i_imm),
	.f(cmpmux_out)
);

/*
 * PC
 */
pc_register pc
(
    .clk(clk),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

assign pc_plus4_out = pc_out + 32'd4;

mux2 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus4_out),
    .b(alu_out),
    .f(pcmux_out)
);

endmodule : datapath
