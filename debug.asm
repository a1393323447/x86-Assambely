mov ax, 0x7c00
mov ds, ax

mov bx, 0x353637        ; mov bx, 0x3637
mov byte [0xf1], 'H'    ; 
mov byte [0xf2], 0x3839
jmp $
times 510-($-$$) db 0
db 0x55, 0xaa