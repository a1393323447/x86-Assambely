; 不产生进位的加法
mov ax, 0x0001
mov bx, 0x0002
add ax, bx
; 产生进位的加法
mov ax, 0xf000
mov bx, 0x1000
add ax, bx
; 不产生借位的减法
mov cx, 0x0003
mov dx, 0x0002
sub cx, dx
; 产生借位的减法
mov cx, 0x0001
mov dx, 0x0002
sub cx, dx

; 当发生进位或者借位的时候, cf 标志位会被置为 1, 否则为 0
; 指令 inc [increase] dec [decrease], 自增, 自减, 不会影响 cf 位

dead_loop: jmp dead_loop

times 510-($-$$) db 0
db 0x55, 0xaa