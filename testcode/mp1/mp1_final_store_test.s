mp1_final_store:
.align 4
.section .text
.global _start

_start:
	#  get mem addresses
	la x2, sb_test
	la x3, sh_test
	la x4, sw_test

	# test word
	lw x1, sw_pattern
	sw x1, 0(x4)
	lw x5, sw_test	# DEADBEEF

	# test half
	lw x1, sh_pattern
	sh x1, 2(x3)
	lw x6, sh_test	# 0x87650000

	sh x1, 0(x3)
	lw x6, sh_test	# 0x87654321

	# test byte
	lw x1, sb_pattern
	sb x1, 1(x2)
	lw x7, sb_test	# 0x000056

	sb x1, 3(x2)
	lw x7, sb_test	# 0x12005600

	sb x1, 2(x2)
	lw x7, sb_test	# 0x12345600

	sb x1, 0(x2)
	lw x7, sb_test	# 0x12345678

halt:
	beq x0, x0, halt

.section .rodata
sw_pattern: .word 0xDEADBEEF
sh_pattern: .word 0x87654321
sb_pattern: .word 0x12345678
sb_test: .word 0x00000000
sh_test: .word 0x00000000
sw_test: .word 0x00000000
