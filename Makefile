compile: $(T).asm
	nasm -f bin $(T).asm -o $(T).bin
clean:
	rm *.bin