module mp1_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;
logic mem_resp;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
logic [15:0] errcode;
logic [31:0] mem_address;
logic [31:0] mem_rdata;
logic [31:0] mem_wdata;
logic [31:0] write_data;
logic [31:0] write_address;
logic write;
logic [31:0] registers [32];
logic halt;
logic [63:0] order;

initial
begin
    clk = 0;
    order = 0;
end

/* Clock generator */
always #5 clk = ~clk;

assign registers = dut.datapath.regfile.data;
assign halt = dut.load_pc & (dut.datapath.pc_out == dut.datapath.pcmux_out);

always @(posedge clk)
begin
    if (mem_write & mem_resp) begin
        write_address = mem_address;
        write_data = mem_wdata;
        write = 1;
    end else begin
        write_address = 32'hx;
        write_data = 32'hx;
        write = 0;
    end
    if (halt) $finish;
    if (dut.load_pc) order = order + 1;
end

mp1 dut
(
    .clk,
    .mem_resp,
    .mem_rdata,
    .mem_read,
    .mem_write,
    .mem_byte_enable,
    .mem_address,
    .mem_wdata
);

memory memory
(
    .clk,
    .read(mem_read),
    .write(mem_write),
    .wmask(mem_byte_enable),
    .address(mem_address),
    .wdata(mem_wdata),
    .resp(mem_resp),
    .rdata(mem_rdata)
);

riscv_formal_monitor_rv32i monitor
(
  .clock(clk),
  .reset(1'b0),
  .rvfi_valid(dut.load_pc),
  .rvfi_order(order),
  .rvfi_insn(dut.datapath.IR.data),
  .rvfi_trap(dut.control.trap),
  .rvfi_halt(halt),
  .rvfi_intr(1'b0),
  .rvfi_rs1_addr(dut.control.rs1_addr),
  .rvfi_rs2_addr(dut.control.rs2_addr),
  .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.datapath.rs1_out : 0),
  .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.datapath.rs2_out : 0),
  .rvfi_rd_addr(dut.load_regfile ? dut.datapath.rd : 5'h0),
  .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.datapath.regfilemux_out : 0),
  .rvfi_pc_rdata(dut.datapath.pc_out),
  .rvfi_pc_wdata(dut.datapath.pcmux_out),
  .rvfi_mem_addr(mem_address),
  .rvfi_mem_rmask(dut.control.rmask),
  .rvfi_mem_wmask(dut.control.wmask),
  .rvfi_mem_rdata(dut.datapath.mdrreg_out),
  .rvfi_mem_wdata(dut.datapath.mem_wdata),
  .errcode(errcode)
);

endmodule : mp1_tb
