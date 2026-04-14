addi x1,  x0, 25

addi x10, x0, 1
addi x11, x0, 2
addi x12, x0, 3

sw   x1, 8(x0)

addi x13, x0, 4
addi x14, x0, 5
addi x15, x0, 6

lw   x2, 8(x0)

addi x16, x0, 7
addi x17, x0, 8
addi x18, x0, 9

sw   x2, 12(x0)

addi x19, x0, 10
addi x20, x0, 11
addi x21, x0, 12

beq  x1, x2, taken
addi x3,  x0, 111

taken:
addi x22, x0, 13
addi x23, x0, 14
addi x24, x0, 15

addi x4,  x0, 222

bne  x1, x2, wrong2
addi x5,  x0, 77

j stop

wrong2:
addi x6,  x0, 123

stop:
j stop