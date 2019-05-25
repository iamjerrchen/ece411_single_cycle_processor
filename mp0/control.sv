import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    /* Input and output port declarations */
	 input clk,
	 
	 /* Datapath controls */
	 input rv32i_reg rs1,
	 input rv32i_reg rs2,
	 input rv32i_opcode opcode,
	 input logic [2:0] funct3,
	 input logic [6:0] funct7, // mp1: reg to reg ops
	 input logic br_en,
	 
	 output logic load_pc,
	 output logic load_ir,
	 output logic load_regfile,
	 output logic load_mar,
	 output logic load_mdr,
	 output logic load_data_out,
	 
	 output logic pcmux_sel,
	 output logic alumux1_sel,
	 output logic [2:0] alumux2_sel,
	 output logic [1:0] regfilemux_sel,
	 output logic marmux_sel,
	 output logic cmpmux_sel,
	 output branch_funct3_t cmpop,
	 output alu_ops aluop,

    /* Memory signals */
	 input mem_resp,
	 output logic mem_read,
	 output logic mem_write,
	 output rv32i_mem_wmask mem_byte_enable
);

/* -----------------Verification-Monitor-Start---------------- */
/*
* The following ~54 lines of code have been added to help you drive the
* verification monitor. This is not required but we think it will help you
* with testing so we've tried to make it as easy as possible for you to get it
* up and running.
* */
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;

assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

always_comb
begin : trap_check
    trap = 0;
    rmask = 0;
    wmask = 0;

    case (opcode)
        op_lui, op_auipc, op_imm:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/* -------------------Verification-Monitor-END-------------------- */

enum int unsigned {
    /* List of states */
	 fetch1,
	 fetch2,
	 fetch3,
	 decode,
	 s_reg, // reg-reg op
	 s_imm,
	 s_lui,
	 s_auipc,
 	 s_br,
	 s_calc_addr,
	 s_ldr1,
	 s_ldr2,
	 s_str1,
	 s_str2
} state, next_state;

always_comb
begin : state_actions
    /* Default output assignments */
	 load_pc = 1'b0;
	 load_ir = 1'b0;
	 load_regfile = 1'b0;
	 load_mar = 1'b0;
	 load_mdr = 1'b0;
	 load_data_out = 1'b0;
	 
	 pcmux_sel = 1'b0;
	 alumux1_sel = 1'b0;
	 alumux2_sel = 3'd0;
	 regfilemux_sel = 2'b00;
	 marmux_sel = 1'b0;
	 cmpmux_sel = 1'b0;
	 cmpop = branch_funct3_t'(funct3);
	 aluop = alu_ops'(funct3);
	 
	 mem_read = 1'b0;
	 mem_write = 1'b0;
	 mem_byte_enable = 4'b1111;
	 rs1_addr = 5'b00000;
	 rs2_addr = 5'b00000;
	 
    /* Actions for each state */
	 case(state)
		fetch1: begin
			/* MAR <= PC */
			load_mar = 1;
		end
		
		fetch2: begin
			/* Read memory */
			mem_read = 1;
			load_mdr = 1;
		end
		
		fetch3: begin
			/* Load IR */
			load_ir = 1;
		end
		
		decode: /* Do nothing */;
		
		s_reg: begin /* Forced all register to register ops to be add */
			aluop = alu_add;
			rs1_addr = rs1;
			rs2_addr = rs2;
			load_pc = 1'd1;
			load_regfile = 1'd1;
			alumux2_sel = 3'd4;
		end
		
		s_imm: begin /* Reference Sec 2.3 */
			load_regfile = 1;
			load_pc = 1;
			rs1_addr = rs1;
			case(funct3) // 3 bit subset in instruction
				slt: begin // SLTI
					cmpop = blt;
					regfilemux_sel = 2'd1;
					cmpmux_sel = 1;
				end
				sltu: begin // SLTIU
					cmpop = bltu;
					regfilemux_sel = 2'd1;
					cmpmux_sel = 1;
				end
				sr: if(funct7[5] == 1'b1) aluop = alu_sra; // SRAI
					// else aluop = alu_ops'(funct3);
				default: aluop = alu_ops'(funct3); // other immediate instructions
			endcase
		end
		
		// Load upper immediate (U type)
		s_lui: begin
			load_regfile = 1;
			load_pc = 1;
			regfilemux_sel = 2'd2;
			rs1_addr = rs1;
		end
		
		// Add upper immediate PC (U type)
		s_auipc: begin
			/* DR <= PC + u_imm */
			load_regfile = 1;
			
			// PC is the first input to the ALU_ops
			alumux1_sel = 1;
			
			// the u-type immediate is the second input to the ALU
			alumux2_sel = 3'd1;
			
			// in the case of auipc, funct3 is some random bits so we
			// must explicitly set the aluop
			aluop = alu_add;
			
			/* PC <= PC + 4 */
			load_pc = 1;
		end
		
		// Branch
		s_br: begin
			pcmux_sel = br_en;
			load_pc = 1;
			alumux1_sel = 1;
			alumux2_sel = 3'd2;
			aluop = alu_add;
			rs1_addr = rs1;
			rs2_addr = rs2;
		end
		
		// Calculate address
		s_calc_addr: begin
			aluop = alu_add;
			load_mar = 1;
			marmux_sel = 1;
			case(opcode)
				op_store: begin // SW
					alumux2_sel = 3'd3;
					load_data_out = 1;
				end
				default: /* Currently only SW or LW */ ;
			endcase
		end
		
		// Load state 1
		s_ldr1: begin
			load_mdr = 1;
			mem_read = 1;
		end
		
		// Load state 2
		s_ldr2: begin
			regfilemux_sel = 2'd3;
			load_regfile = 1;
			load_pc = 1;
			rs1_addr = rs1;
		end
		
		// Store state 1
		s_str1: mem_write = 1;
		
		// Store state 2
		s_str2: begin
			load_pc = 1;
			rs1_addr = rs1;
			rs2_addr = rs2;
		end
		
		default: /* Do nothing */;
		
	 endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  next_state = state;
	  case(state)
			fetch1: next_state = fetch2;
			fetch2: if (mem_resp) next_state = fetch3;
			fetch3: next_state = decode;
			
			decode: begin
				case(opcode)
					op_reg: next_state = s_reg;
					op_imm: next_state = s_imm;
					op_lui: next_state = s_lui;
					op_load: next_state = s_calc_addr;
					op_store: next_state = s_calc_addr;
					op_auipc: next_state = s_auipc;
					op_br: next_state = s_br;
					default: $display("decode state: Unknown opcode");
				endcase
			end
			
			s_reg: next_state = fetch1;
			s_imm: next_state = fetch1;
			s_lui: next_state = fetch1;
			s_auipc: next_state = fetch1;
			s_br: next_state = fetch1;
			
			s_calc_addr: begin
				case(opcode)
					op_load: next_state = s_ldr1;
					op_store: next_state = s_str1;
					default: $display("s_calc_addr state: Unknown opcode");
				endcase
			end
			
			s_ldr1: if(mem_resp) next_state = s_ldr2;
			s_ldr2: next_state = fetch1;
			
			s_str1: if(mem_resp) next_state = s_str2;
			s_str2: next_state = fetch1;
			
			default: next_state = fetch1;
		endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : control
