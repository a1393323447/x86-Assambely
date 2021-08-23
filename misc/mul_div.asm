; 8  位乘法
; 结果储存在 ax
mov al, 0xf0
mov ah, 0x02
mul ah
; 16 位乘法
; 结果储存在 dx:ax
mov ax, 0xf000
mov bx, 0x0002
mul bx
; 16 位除法
; 商存在 al 里, 余数存在 ah 里
mov ax, 0x0004
mov bl, 0x02
div bl
; 32 位除法
; 商存在 ax 里, 余数存在 
mov dx, 0x0008
mov ax, 0x0006
mov cx, 0x0002
div cx
jmp $

times 510-($-$$) db 0
db 0x55, 0xaa