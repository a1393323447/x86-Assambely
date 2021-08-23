; call 指令
; ret  指令
; equ  指令
; xor, not, and 运算
; jz   指令
; section 分段

NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff

section code align=16 vstart=0x7c00

    mov si, SayHello    ; ds 默认为 0x0000
    xor di, di          ; 将 di 设置为 0
    call PrintChars
    jmp End

PrintChars:
    .setup:
        mov ax, VIDEOMEM
        mov es, ax          ; 设置为显存起始地址
        mov cx, STRINGLEN   ; 设置循环次数
        mov bh, SETCHAR     ; 设置字符属性
    .print:
        mov bl, [ds:si] ; 读取字符
        inc si          ; 读取地址自增
        mov [es:di], bl ; 输出字符
        inc di          ; 输出地址自增
        mov [es:di], bh ; 输出字符属性
        inc di          ; 输出地址自增
        or  bl, NUL
        jz  .return     ; 如果 bl == 0x00, 就跳转到 .return
        loop .print     ; 循环
    .return:
        ret

SayHello db 'Hello'
         db 0x00   ; 终结符

End:    ; 必须要写在最后, 如果不是最后的话, SayHello 等就会到第二个扇区了!
    jmp End   ; dead loop
    times 510-($-$$) db 0
    db 0x55, 0xaa