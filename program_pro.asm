SETCHAR equ 0x07
section head align=16 vstart=0
Size dd ProgramEnd ; 4B 0x00
SegmentAddr:
    CodeSeg dd section.code.start ; 4B 0x04
    DataSeg dd section.data.start ; 4B 0x08
    StackSeg dd section.stack.start; 4B 0x0c
SegmentNum:
    SegNum db (SegmentNum - SegmentAddr)/4 ; 1B 0x10
Entry:
    dw CodeStart ; 2B 0x11  偏移地址
    dd section.code.start ; 4B 0x13 段地址

section code align=16 vstart=0
CodeStart:
    mov ax, [StackSeg]  ; 设置栈空间, 使用程序自己的栈空间
    mov sp, StackEnd
    mov ss, ax

    mov ax, [DataSeg]   ; 传参
    mov ds, ax          ; 将段地址设置为字符串所在位置
    call PrintLines     ; 调用函数
    jmp $

PrintLines:
    .setup:
        push ax
        push bx
        push cx
        push dx

        mov cx, HelloEnd - SayHello ; 计算字符串长度
        xor si, si
        mov bl, SETCHAR
    .putc:
        mov al, [si]
        inc si
        mov ah, 0x0e    ; 设置中断属性, 0x0e: 打字机模式
        int 0x10        ; 使用 0x10 号中断
        loop .putc
    .return:
        pop dx
        pop cx
        pop bx
        pop ax
        ret
section data align=16 vstart=0
SayHello db 'Hello there!'
         db 0x0d, 0x0a
         db 'This is a test!'
         db 0x0d, 0x0a
         db 'If you see this message, then the test successed.'
         db 0x00
HelloEnd:

section stack align=16 vstart=0
times 128 db 0
StackEnd:

section end align=16
ProgramEnd: