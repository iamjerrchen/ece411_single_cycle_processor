//DO NOT CHANGE DOWNPATH MODULE OR SIGNAL NAMES IN THIS FILE
//if you name, for example, your instruction register something other than IR,
//it will cause a compile error in this file. If you change this file to match
//your naming instead of changing your naming to match this file, you will
//break the autograder, leading to a manual regrade which will incur a grade
//penalty

module mp2_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;
logic pmem_resp;
logic pmem_read;
logic pmem_write;
logic [31:0] pmem_address;
logic [255:0] pmem_wdata;
logic [255:0] pmem_rdata;

logic [15:0] errcode;

/* autograder signals */
logic [255:0] write_data;
logic [27:0] write_address;
logic write;
logic halt;
logic sm_error;
logic pm_error;
logic [31:0] registers [32];
logic [255:0] data0 [8];
logic [255:0] data1 [8];
logic [23:0] tags0 [8];
logic [23:0] tags1 [8];
logic [63:0] order;

initial
begin
    clk = 0;
    order = 0;
    halt = 0;
end

/* Clock generator */
always #5 clk = ~clk;

assign registers = dut.cpu.datapath.regfile.data;
assign data0 = dut.cache.datapath.line[0].data;
assign data1 = dut.cache.datapath.line[1].data;
assign tags0 = dut.cache.datapath.tag[0].data;
assign tags1 = dut.cache.datapath.tag[1].data;

always @(posedge clk)
begin
    if (pmem_write & pmem_resp) begin
        write_address = pmem_address[31:5];
        write_data = pmem_wdata;
        write = 1;
    end else begin
        write_address = 27'hx;
        write_data = 256'hx;
        write = 0;
    end/*
    if ((|errcode) || pm_error || sm_error || (dut.cpu.load_pc && dut.cpu.control.trap)) begin
        halt = 1;
        $display("Halting with error!");
        $finish;
    end else */
    if (dut.cpu.load_pc & (dut.cpu.datapath.pc_out == dut.cpu.datapath.pcmux_out))
    begin
        halt = 1;
        $display("Halting without error");
        $finish;
    end
    if (dut.cpu.load_pc) order = order + 1;
end


mp2 dut(
    .*
);

physical_memory memory(
    .clk,
    .read(pmem_read),
    .write(pmem_write),
    .address(pmem_address),
    .wdata(pmem_wdata),
    .resp(pmem_resp),
    .error(pm_error),
    .rdata(pmem_rdata)
);

shadow_memory sm (
    .clk,
    .valid(dut.cpu.load_pc),
    .rmask(dut.cpu.control.rmask),
    .wmask(dut.cpu.control.wmask),
    .addr(dut.mem_address),
    .rdata(dut.cpu.datapath.mdrreg_out),
    .wdata(dut.cpu.datapath.mem_wdata),
    .pc_rdata(dut.cpu.datapath.pc_out),
    .insn(dut.cpu.datapath.IR.data),
    .error(sm_error)
);

riscv_formal_monitor_rv32i monitor
(
  .clock(clk),
  .reset(1'b0),
  .rvfi_valid(dut.cpu.load_pc),
  .rvfi_order(order),
  .rvfi_insn(dut.cpu.datapath.IR.data),
  .rvfi_trap(dut.cpu.control.trap),
  .rvfi_halt(halt),
  .rvfi_intr(1'b0),
  .rvfi_rs1_addr(dut.cpu.control.rs1_addr),
  .rvfi_rs2_addr(dut.cpu.control.rs2_addr),
  .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.cpu.datapath.rs1_out : 0),
  .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.cpu.datapath.rs2_out : 0),
  .rvfi_rd_addr(dut.cpu.load_regfile ? dut.cpu.datapath.rd : 5'h0),
  .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.cpu.datapath.regfilemux_out : 0),
  .rvfi_pc_rdata(dut.cpu.datapath.pc_out),
  .rvfi_pc_wdata(dut.cpu.datapath.pcmux_out),
  .rvfi_mem_addr(dut.mem_address),
  .rvfi_mem_rmask(dut.cpu.control.rmask),
  .rvfi_mem_wmask(dut.cpu.control.wmask),
  .rvfi_mem_rdata(dut.cpu.datapath.mdrreg_out),
  .rvfi_mem_wdata(dut.cpu.datapath.mem_wdata),
  .errcode(errcode)
);

endmodule : mp2_tb

