; 结论: 初始化时, cs == ds == es
; [ptr] -> ds:ptr 处的数据
section code align=16 vstart=0x7c00
mov ax, 0x0000
mov bx, 0x0000
mov cx, 0x0000
mov dx, 0x0000

mov ax, [ds:0x00]
mov bx, [0x00]
mov cx, [cs:0x00]

mov ax, 0xff
mov ds, ax

mov dx, [0x00]
mov ax, [cs:0x00]

jmp $

times 510-($-$$) db 0
db 0x55, 0xaa