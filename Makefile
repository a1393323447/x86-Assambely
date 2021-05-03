compile: $(T).asm
	nasm -f bin $(T).asm -o $(T).bin
clean: 	*.bin
	del *.bin