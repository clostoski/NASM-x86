basic:
	nasm -g -f elf -F dwarf secded.asm
	gcc -m32 secded.o -o secded

run:
	./secded

gdb:
	gdb ./secded

gui:
	gdb -tui ./secded
