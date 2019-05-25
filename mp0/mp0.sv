import rv32i_types::*;

module mp0
(
	input logic clk,

	/* Memory to Control */
	input logic mem_resp,

	/* Memory to Datapath */
	input rv32i_word mem_rdata,
	
	/* Control to Memory */
	output logic mem_read,
	output logic mem_write,
	output logic [3:0] mem_byte_enable,
	
	/* Datapath to Memory */
	output rv32i_word mem_address,
	output rv32i_word mem_wdata
);

/* Internal Signals */
/* Control to Datapath */
logic load_pc, load_ir, load_regfile, load_mar;
logic load_mdr, load_data_out;

logic pcmux_sel, alumux1_sel;
logic [2:0] alumux2_sel, regfilemux_sel;
logic marmux_sel, cmpmux_sel;

alu_ops aluop;
branch_funct3_t cmpop;

/* Datapath to Control */
logic [4:0] rs1, rs2;
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic br_en;

/* Instantiate MP 0 top level blocks here */
datapath datapath
(
	.clk(clk),
	.mem_rdata(mem_rdata),
	
	.load_pc(load_pc),
	.load_ir(load_ir),
	.load_regfile(load_regfile),
	.load_mar(load_mar),
	.load_mdr(load_mdr),
	.load_data_out(load_data_out),
	
	.pcmux_sel(pcmux_sel),
	.alumux1_sel(alumux1_sel),
	.alumux2_sel(alumux2_sel),
	.regfilemux_sel(regfilemux_sel),
	.marmux_sel(marmux_sel),
	.cmpmux_sel(cmpmux_sel),
	
	.aluop(aluop),
	.cmpop(cmpop),
	// output
	.rs1(rs1),
	.rs2(rs2),
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.br_en(br_en),
	
	.mem_address(mem_address),
	.mem_wdata(mem_wdata)
); 

control control
(
	.clk(clk),
	.rs1(rs1),
	.rs2(rs2),
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.br_en(br_en),
	.mem_resp(mem_resp),
	// output
	.load_pc(load_pc),
	.load_ir(load_ir),
	.load_regfile(load_regfile),
	.load_mar(load_mar),
	.load_mdr(load_mdr),
	.load_data_out(load_data_out),
	
	.pcmux_sel(pcmux_sel),
	.alumux1_sel(alumux1_sel),
	.alumux2_sel(alumux2_sel),
	.regfilemux_sel(regfilemux_sel),
	.marmux_sel(marmux_sel),
	.cmpmux_sel(cmpmux_sel),
	.cmpop(cmpop),
	.aluop(aluop),
	
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_byte_enable(mem_byte_enable)
);

endmodule : mp0
