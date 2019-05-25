import rv32i_types::*;

module mp2 #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
	 parameter ways     = 2
)
(
	input logic clk,

	/* Memory to Control */
	input logic pmem_resp,

	/* Memory to Datapath */
	input logic [s_line-1:0] pmem_rdata,
	
	/* Control to Memory */
	output logic pmem_read,
	output logic pmem_write,
	
	/* Datapath to Memory */
	output rv32i_word pmem_address,
	output logic [s_line-1:0] pmem_wdata
);

logic mem_read, mem_write;
logic mem_resp;
rv32i_word mem_address;
rv32i_word mem_wdata, mem_rdata;

/* Processor to Cache */
logic [3:0] mem_byte_enable;

cpu cpu
(
	.clk(clk),

	/* Cache to CPU Control */
	.mem_resp(mem_resp),

	/* Cache to CPU Datapath */
	.mem_rdata(mem_rdata),
	
	/* Control to Cache */
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_byte_enable(mem_byte_enable),
	
	/* Datapath to Cache */
	.mem_address(mem_address),
	.mem_wdata(mem_wdata)
);

cache cache
(
	.clk(clk),
	
	/* Physical Memory to Cache Datapath */
	.pmem_rdata(pmem_rdata),
	
	/* Physical Memory to Cache Control */
	.pmem_resp(pmem_resp),
		
	/* Processor to Cache Control */
	.mem_read(mem_read),
	.mem_write(mem_write),
	
	/* Processor to Bus Adapter */
	.address(mem_address),
	.mem_wdata(mem_wdata),
	.mem_byte_enable(mem_byte_enable),

	/* Cache Datapath to Physical Memory */
	.pmem_wdata(pmem_wdata),
	
	/* Cache Control to Physical Memory */
	.pmem_write(pmem_write),
	.pmem_read(pmem_read),
	.pmem_address(pmem_address),
	
	/* Cache Control to CPU Control */
	.mem_resp(mem_resp),
		
	/* Bus Adapter to Processor */
	.mem_rdata(mem_rdata)
);

endmodule : mp2
