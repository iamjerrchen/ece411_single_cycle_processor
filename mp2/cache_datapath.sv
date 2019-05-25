import rv32i_types::*;

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
	 parameter ways     = 2
)
(
	input clk,	
	input rv32i_word address,
	
	// From Cache Control
	input data_read,	
	input data_write,
	input force_data_write,
	input force_data_read,
	input lru_load,
	input lru_read,
	input tag_load,
	input tag_read,
	input valid_load,
	input valid_read,
	input dirty_in,
	input dirty_read,
	input dirty_load,
	input dirty_load_sel,
	
	// From Physical Memory
	input logic [s_line-1:0] pmem_rdata,
	
	// From Bus Adapter
	input logic [31:0] mem_byte_enable256,
	input logic [s_line-1:0] mem_wdata256,
	
	// To Cache Control
	output logic hit_control,
	output logic [s_tag-1:0] tag_array_out,
	output logic dirty_bit,
	
	// To Physical Memory
	output logic [s_line-1:0] pmem_wdata,
	
	// To Bus Adapter
	output logic [s_line-1:0] mem_rdata256
);

//  Address
logic [s_index-1:0] set_field;
logic [s_tag-1:0] tag_field;

assign set_field = address[7:5];
assign tag_field = address[31:8];

// Data Array
logic [s_line-1:0] dataout0, dataout1, dataout_mux_out, datain_mux_out;
logic [31:0] write_en_mux_out0, write_en_mux_out1;
logic [1:0] write_en_mux_sel0, write_en_mux_sel1, dataout_mux_sel;

// LRU
logic lru_out, lru_in, intl_lru_load;
 
// Tag Array
logic intl_tag_load0, intl_tag_load1;
logic [s_tag-1:0] tag_out [ways];

// CMP
logic cmp_out [ways];
logic hit0, hit1;

// Valid Array
logic intl_valid_load0, intl_valid_load1;
logic valid_out [ways];

// Dirty
logic intl_dirty_load0, intl_dirty_load1;
logic dirty_load_mux_out0, dirty_load_mux_out1;
logic dirty_out [ways];

/*
 * Data Array
 */
data_array line [ways]
(
    .clk(clk),
	 .read(data_read),
    .write_en({write_en_mux_out0, write_en_mux_out1}),
    .index(set_field),
    .datain(datain_mux_out),
    // output
	 .dataout({dataout0, dataout1})
);

mux2 #(.width(s_line)) datain_mux
(
	.sel(force_data_write),
	.a(mem_wdata256),
	.b(pmem_rdata),
	// output
	.f(datain_mux_out)
);

assign write_en_mux_sel0[0] = data_write && hit0;
assign write_en_mux_sel0[1] = (!lru_out) && force_data_write;

assign write_en_mux_sel1[0] = data_write && hit1;
assign write_en_mux_sel1[1] = lru_out && force_data_write;

mux4 #(.width(s_mask)) write_en_mux [ways]
(
	.sel({write_en_mux_sel0, write_en_mux_sel1}),
	.a(32'd0),
	.b(mem_byte_enable256),
	.c(32'hffffffff),
	.d(32'hffffffff),
	// output
	.f({write_en_mux_out0, write_en_mux_out1})
);

assign dataout_mux_sel[0] = hit0 || (force_data_read && !lru_out);
assign dataout_mux_sel[1] = hit1 || (force_data_read && lru_out);

mux4 #(.width(s_line)) dataout_mux
(
	.sel(dataout_mux_sel),
	.a(256'd0), // Ignore
	.b(dataout0),
	.c(dataout1),
	.d(256'd0), // Ignore
	// output
	.f(dataout_mux_out)
);

assign mem_rdata256 = dataout_mux_out;
assign pmem_wdata = dataout_mux_out;

/*
 * LRU
 */
assign intl_lru_load = lru_load && (hit0 || hit1);

array #(.width(1)) LRU
(
	.clk(clk),
	.read(lru_read),
	.load(intl_lru_load),
	.index(set_field),
	.datain(lru_in),
	// output
	.dataout(lru_out)
);

mux2 #(.width(1)) lru_in_mux
(
	.sel(hit0),
	.a(1'd0),
	.b(1'd1),
	// output
	.f(lru_in)
);

/*
 * Tag Array
 */
assign intl_tag_load0 = tag_load && !lru_out;
assign intl_tag_load1 = tag_load && lru_out;

array #(.width(s_tag)) tag [ways]
(
	.clk(clk),
	.read(tag_read),
   .load({intl_tag_load0, intl_tag_load1}),
   .index(set_field),
   .datain(tag_field),
	// output
	.dataout(tag_out)
);

mux2 #(.width(s_tag)) tag_out_mux
(
	.sel(lru_out),
	.a(tag_out[0]),
	.b(tag_out[1]),
	// output
	.f(tag_array_out)
);

/*
 * Tag Compare
 */
assign hit0 = cmp_out[0] && valid_out[0];
assign hit1 = cmp_out[1] && valid_out[1];
assign hit_control = hit0 || hit1;

tag_cmp cmp [ways]
(
	.addr_tag(tag_field),
	.tag_out(tag_out),
	// output
	.out(cmp_out)
);

/*
 * Valid Array
 */
assign intl_valid_load0 = valid_load && !lru_out;
assign intl_valid_load1 = valid_load && lru_out;

array #(.width(1)) valid [ways]
(
	.clk(clk),
	.read(valid_read),
	.load({intl_valid_load0, intl_valid_load1}),
	.index(set_field),
	.datain(1'd1),
	// output
	.dataout(valid_out)
);

/*
 * Dirty Array
 */
assign intl_dirty_load0 = dirty_load_mux_out0 && dirty_load;
assign intl_dirty_load1 = dirty_load_mux_out1 && dirty_load;

array #(.width(1)) dirty [ways]
(
	.clk(clk),
	.read(dirty_read),
	.load({intl_dirty_load0, intl_dirty_load1}),
	.index(set_field),
	.datain(dirty_in),
	// output
	.dataout(dirty_out)
);

mux2 #(.width(1)) dirty_load_mux_out [ways]
(
	.sel(dirty_load_sel),
	.a({hit0, hit1}),
	.b({!lru_out, lru_out}),
	// output
	.f({dirty_load_mux_out0, dirty_load_mux_out1})
);

mux2 #(.width(1)) dirty_mux_out
(
	.sel(lru_out),
	.a(dirty_out[0]),
	.b(dirty_out[1]),
	// output
	.f(dirty_bit)
);
 
endmodule : cache_datapath

