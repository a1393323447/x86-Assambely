; loop指令: 使用 cx 设置循环次数, 会自动将 cx 减一
; 标号:
;     (循环体)...
;     loop 标号

; 设定循环次数
mov cx, 100
; 初始化 ax
mov ax, 0x0000
; 循环
sum:
    add ax, cx
    loop sum
jmp $

times 510-($-$$) db 0
db 0x55, 0xaa