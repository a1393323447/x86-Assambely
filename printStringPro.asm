; 改变光标位置 -> 通过写入显卡寄存器实现
; 显卡寄存器很多, 通过 0x3d4 端口下发显卡寄存器编号
; 再从 0x3d5 读写对应编号寄存器的值
; 光标的位置由两个寄存器的值决定: 0x0e(光标位置高 8 位) 0x0f(光标位置低 8 位)
; 一个屏幕一行可显示 80 个字符
; eg: 若算得的光标位置为 185, 185 / 80 = 2 .. 25
;     那么光标就在 2 行 25 列
; 
; 0x0d: 回车 -> 光标位置回到行首
; 0x0a: 换行 -> 光标位置换到下一行, 不回到行首

SETCHAR equ 0x07
VIDEORAM equ 0xb800
NUL equ 0x00

section code align=16 vstart=0x7c00
main:
    mov di, Hello
    call PrintString
    jmp End

PrintString:
    .setup:
        push ax
        push bx
        push cx
        push dx

        mov bh, SETCHAR
        mov ax, VIDEORAM
        mov ds, ax
        xor si, si
    .print:
        mov bl, [es:di]
        inc di
        or  bl, NUL
        jz  .return
        cmp bl, 0x0d
        jz  .putCR
        cmp bl, 0x0a
        jz  .putLF
        mov [ds:si], bl
        inc si
        mov [ds:si], bh
        inc si
        jmp .print
    .putCR:
        mov bl, 160
        mov ax, si
        div bl
        shr ax, 8   ; 余数从 ah 位移到 al 中
        sub si, ax  ; 退格
        call SetCursor
        jmp .print
    .putLF:
        add si, 160
        call SetCursor
        jmp .print
    .return:
        pop dx
        pop cx
        pop bx
        pop ax
        ret

SetCursor:
    .setup:
        push ax
        push bx
        push cx
        push dx

        mov ax, si
        mov dx, 0   ; 商: ax, 余数: dx
        mov bx, 2   ; 一定能被 2 整除
        div bx

        mov bx, ax
    .set:
        mov dx, 0x3d4
        mov al, 0x0e
        out dx, al

        mov dx, 0x3d5
        mov al, bh
        out dx, al

        mov dx, 0x3d4
        mov al, 0x0f
        out dx, al

        mov dx, 0x3d5
        mov al, bl
        out dx, al
    .return:
        pop dx
        pop cx
        pop bx
        pop ax
        ret

Hello db 'Hello!'
      db 0x0d, 0x0a
      db 'This is a test!'
      db 0x0a
      db 'Woo!'
      db 0x0d
      db 'Ha Ha'
      db 0x00
End:
    jmp End
    times 510-($-$$) db 0
    db 0x55, 0xaa