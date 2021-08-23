; ss: 栈底指针
; sp: 栈顶指针
; 因为栈是从 高地址 往 低地址生长的
; 所以每一次 push 操作都会使得 sp 减少
; pop 操作则会使得 sp 增加
; 当一个减去比自己大的数时, 会发生溢出
; 最高的符号位被抛弃 

mov bx, 0x0000
mov ss, bx
mov sp, 0x0000
mov ax, 0x0001
push ax
pop ax

jmp $ ; dead loop
times 510-($-$$) db 0
db 0x55, 0xaa