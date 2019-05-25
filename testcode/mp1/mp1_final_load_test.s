test_mp1_final_load:
.align 4
.section .text
.global _start


_start:
	lb x1, lb_test		# 0xFFFFFFB2
	lb x1, lb_test+1	# 0xFFFFFFA3
	lb x1, lb_test+2	# 0xFFFFFF94
	lb x1, lb_test+3	# 0xFFFFFF85

	lh x2, lh_test+1	# should default to lh_test
	lh x2, lh_test+2	# 0xFFFFDEAD
	lh x2, lh_test		# 0xFFFFBEEF

	lw x3, lw_test		# 0xBEC0FFEE

	lbu x4, lbu_test	# 0x000000B2
	lbu x4, lbu_test+1	# 0x000000A3
	lbu x4, lbu_test+2	# 0x00000094
	lbu x4, lbu_test+3	# 0x00000085

	lhu x5, lhu_test+1	# 0x0000BEEF
	lhu x5, lhu_test+2	# 0x0000DEAD
	lhu x5, lhu_test	# 0x0000BEEF

	lb x6, lbz_test		# 0x00000048
	lb x6, lbz_test+1	# 0x00000057
	lb x6, lbz_test+2	# 0x00000066
	lb x6, lbz_test+3	# 0x00000075

	lh x7, lhz_test+1	# 0x00003A53
	lh x7, lhz_test+2	# 0x00005EED
	lh x7, lhz_test		# 0x00003A53

halt:		
	beq x0, x0, halt

.section .rodata
lb_test: .word 0x8594A3B2
lbz_test: .word 0x75665748
lh_test: .word 0xDEADBEEF
lhz_test: .word 0x5EED3A53
lw_test: .word 0xBEC0FFEE
lbu_test: .word 0x8594A3B2
lhu_test: .word 0xDEADBEEF
