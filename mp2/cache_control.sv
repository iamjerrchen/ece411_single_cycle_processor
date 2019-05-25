import rv32i_types::*;

module cache_control #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rv32i_word address,
	
	// From Processor
	input mem_read,
	input mem_write,
	
	// From Cache Datapath
	input hit_control,
	input logic [s_tag-1:0] tag_array_out,
	input dirty_bit,
	
	// From Physical Memory
	input pmem_resp,

	// To Cache Datapath
	output logic data_read,	
	output logic data_write,
	output logic force_data_write,
	output logic force_data_read,
	output logic lru_load,
	output logic lru_read,
	output logic tag_load,
	output logic tag_read,
	output logic valid_load,
	output logic valid_read,
	output logic dirty_in,
	output logic dirty_read,
	output logic dirty_load,
	output logic dirty_load_sel,
	
	// To Physical Memory
	output logic pmem_write,
	output logic pmem_read,
	output rv32i_word pmem_address,
	
	// To CPU Control
	output logic mem_resp
);

logic mem_op, dirty_bool, clean_bool;

assign mem_op = mem_read || mem_write;
assign dirty_bool = mem_op && !hit_control && dirty_bit;
assign clean_bool = mem_op && !hit_control && !dirty_bit;

enum int unsigned {
   /* List of states */
	s_wait,
	s_hit,
	s_dirty,
	s_miss
} state, next_state;

always_comb
begin : state_actions
	/* Default output assignments */
	data_read = 1'd0;
	data_write = 1'd0;
	force_data_write = 1'd0;
	force_data_read = 1'd0;
	lru_load = 1'd0;
	lru_read = 1'd0;
	tag_load = 1'd0;
	tag_read = 1'd0;
	valid_load = 1'd0;
	valid_read = 1'd0;
	dirty_in = 1'd0;
	dirty_read = 1'd0;
	dirty_load = 1'd0;
	dirty_load_sel = 1'd0;
	
	pmem_write = 1'd0;
	pmem_read = 1'd0;
	pmem_address = 32'd0;
	
	mem_resp = 1'd0;
	
	case(state)
		s_wait: begin
			dirty_read = 1'd1;
			lru_read = 1'd1;
			tag_read = 1'd1;
			valid_read = 1'd1;
			data_read = 1'd1;
		end

		s_hit: begin
			data_write = mem_write;
			data_read = mem_read;
			dirty_read = 1'd1;
			dirty_load = mem_write;
			dirty_in = mem_write;
			lru_load = 1'd1;
			lru_read = 1'd1;
			tag_read = 1'd1;
			valid_read = 1'd1;
			mem_resp = mem_op && hit_control;
		end
		
		s_dirty: begin
			dirty_read = 1'd1;
			dirty_load_sel = 1'd1;
			dirty_load = 1'd1;
			lru_read = 1'b1;
			pmem_write = 1'd1;
			pmem_address = {tag_array_out, address[7:0]};
		end
		
		s_miss: begin
			valid_load = 1'd1;
			force_data_write = pmem_resp;
			tag_load = 1'd1;
			pmem_read = 1'd1;
			pmem_address = address;
		end
	
		default:	/* Do Nothing */;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		s_wait: begin
			if(mem_op) next_state = s_hit;
		end
		
		s_hit: begin
			if(dirty_bool) next_state = s_dirty;
			else if(clean_bool) next_state = s_miss;
			else next_state = s_wait;
		end
		
		s_dirty: begin
			if(pmem_resp) next_state = s_miss;
		end
		
		s_miss: begin
			if(pmem_resp) next_state = s_wait;
		end
		
		default: next_state = s_wait;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : cache_control

