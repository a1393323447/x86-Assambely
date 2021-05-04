; 抛开示例代码自己写
section head align=16 vstart=0
Size dd ProgramEnd  ; 4B 0x00
SegmentAddr:
    CodeSeg dd section.code.start   ; 4B 0x04
    DataSeg dd section.data.start   ; 4B 0x08
    StackSeg dd section.stack.start ; 4B 0x0c
SegmentNum:
    SegNum db (SegmentNum-SegmentAddr)/4
Entry dw CodeStart  ; 偏移地址 2B
      dd section.code.start ; 段地址 4B

section code align=16 vstart=0
    CodeStart:
        mov ax, [DataSeg]
        mov ds, ax
        xor si, si
        call PrintString
        
        jmp $       ; dead loop

    PrintString:
        .setup:
            push ax
            push bx
            push cx
            push dx

            mov bh, 0x07
            mov ax, 0xb800
            mov es, ax
            xor di, di
        .print:
            mov bl, [ds:si]
            inc si
            mov [es:di], bl
            inc di
            mov [es:di], bh
            inc di
            or bl, 0x00
            jnz .print
        .return:
            pop dx
            pop cx
            pop bx
            pop ax
            ret

section data align=16 vstart=0
    Hello db 'Hi! I try to write this program by myself (with a little tips)!'
          db 0x00   ; 终结符
section stack align=16 vstart=0
    resb 128
section end align=16
ProgramEnd: