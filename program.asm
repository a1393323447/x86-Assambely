; 根据 bootLoader 里的设定, program 应该被加载到 1 号扇区
;
; program 的结构:
; --------------------------
;|          head            |
;|          code            |
;|          data            |
;|          stack           |
;|          end             |
; --------------------------
; Head 包含:
;           Size        (program 的大小)
;           CodeSeg     (程序段的起始地址)
;           DataSeg     (数据段的起始地址)
;           StackSeg    (程序栈的起始地址)
;           SegNum      (分段数)
;           Entry       (程序入口点地址)
; 为什么需要 head ?
; 1. 程序的大小是可变的, bootLoader 无法提前得知程序的大小,
;    所以需要在 head 中定义一个 Size 数据, 让 bootLoader 得知程序的大小
;    再根据程序的大小决定读几个扇区
; 2. 程序分了几个段, 各个段的段地址是多少, 而且由于程序被加载到哪块内存并不固定,
;    所以段的实际地址还要重新计算, 所以要提供各个段的起始地址, 和分段数
; 3. 由于程序的第一行并不一定是可执行代码, 所以要告诉 booLoader 程序的入口地址(Entry)
;    而且这个地址也要根据程序被加载到的内存的实际地址进行重定位

NUL equ 0x00
SETCHAR equ 0x07
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff

section head align=16 vstart=0  ; head 中的数据要依靠 数据大小 偏移地址 两个信息提取
    Size dd ProgramEnd  ; 4B 0x00
    SegmentAddr:
        CodeSeg dd section.code.start   ; 4B 0x04, setion.code.start: 代表 code 段的汇编地址
        DataSeg dd section.data.start   ; 4B 0x08
        StackSeg dd section.stack.start ; 4B 0x0c
    SegmentNum:
        SegNum db (SegmentNum - SegmentAddr)/4 ; 1B 0x10, 段的数量
    Entry dw CodeStart          ; 2B 0x11 偏移地址
            dd section.code.start ; 4B 0x13 段地址

section code align=16 vstart=0
    CodeStart:
        mov ax, [DataSeg]   ; 指向 Hello 字符串
        mov ds, ax
        xor si, si
        call PrintString
        jmp $            ; dead loop
    PrintString:
        .setup:
            push ax
            push bx
            push cx
            push dx

            mov ax, VIDEOMEM
            mov es, ax
            xor di, di

            mov bh, SETCHAR
            mov cx, STRINGLEN

        .print:
            mov bl, [ds:si]
            inc si
            mov [es:di], bl
            inc di
            mov [es:di], bh
            inc di
            or  bl, NUL
            jz  .return
            loop .print
        .return:
            pop dx
            pop cx
            pop bx
            pop ax
            ret

section data align=16 vstart=0
    Hello db 'Hello, I come from progam on sector 1, loaded the by bootloader.'
          db 0x00

section stack align=16 vstart=0     ; 程序的栈空间
    resb 128    ; reserve [n] byte, 不会初始化内存空间

section end align=16       ; section 不设置 vstart 参数时, 标号的地址是相对于程序头的偏移
    ProgramEnd: ; 定义一个标号标定程序的结尾, 以供计算程序的大小
