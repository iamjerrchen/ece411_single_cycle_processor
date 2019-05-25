test_mp1_cp1:
.align 4
.section .text
.global _start



_start:
	andi x1, x1, 0	# reset x1
	andi x2, x2, 0	# reset x1

	addi x1, x1, 5	# operand 1
	addi x2, x2, 20 # operand 2

	add x3, x1, x2	# 20+5 = 25

	sub x2, x2, x1	# 20-5 = 15
	sub x4, x1, x2	# 5-15 = -10

	slt x5, x4, x1	# -10 < 5
	slt x5, x1, x4	# 5 < -10

	sltu x5, x4, x1 # x4 < x1 = false
	sltu x5, x1, x4 # x1 < x4 = true

	andi x1, x1, 0	# clear x1
	addi x1, x1, 170 # 0xAA
	andi x2, x2, 0
	addi x2, x2, 85 # 0x55

	or x6, x1, x2	# x6 = 0xFF
	and x6, x6, x1	# x6 = x1 = 0xAA
	xor x6, x6, x6	# clear x6

	addi x2, x6, 4	# x2 = 0100
	addi x6, x6, 1	# x6 = 0001
	sll x7, x6, x2	# x7 = 1 0000
	srl x7, x7, x2	# x7 = 0 0001
	
	xor x7, x7, x7	# clear x7
	addi x7, x7, -1
	sra x7, x7, x2	# no change
	sra x7, x7, x2	# no change	
	
	







halt:
	beq x0, x0, halt


.section .rodata
