test_mp1_cp1:
.align 4
.section .text
.global _start

_start:
	andi x1, x1, 0		# clear x1
	jal x1, jal_test	
	
	jal x1, halt		# should be skipped
	andi x2, x2, 0
	addi x2, x2, 20
	beq x2, x2, halt	# end program

jal_test:
	andi x3, x3, 0
	addi x3, x3, 20
	jalr x1, x1, 4

halt:
	beq x0, x0, halt

.section .rodata
