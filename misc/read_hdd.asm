; 读取位于第 10 扇区的数据(详见 data.asm )

; 学到的知识: 1. 通过LBA方式读取硬盘; 2. 将物理地址转化为逻辑地址; 3. in、out指令; 4. 通过栈保存和还原现场; 

; 端口: 其它设备中的寄存器
; 计算机的主硬盘分配有 8 个端口号
; 分别为 0x1f0 ~ 0x1f7

; 通过 in / out 指令, 与端口交流

; in  destination(al/ax) source(dx/inm8)
; out destination(dx/imm8) source(al/ax)

; LBA 方式 
; Logical Block Addressing (逻辑块寻址)
; 这次主要学习 LBA28 寻址方式 (最大可寻址 128G)
; 1. 在 0x1f2 中写入要读取的扇区数
; 2. 通过 28 位 逻辑号告诉硬盘从哪个逻辑扇区开始读
;    因为端口(0x1f1 ~ 0x1f7)是 8 位的, 所以要用 4 个端口来表示
;
;    [0x1f6]   [0x1f5]   [0x1f4]   [0x1f3]
;     27~24     23~16     15~8       7~0
;    [0x1f6] -> [ 1|  | 1|  |27|26|25|24]
;                 7  6  5  4  3  2  1  0
;
;     第 4 位: 选择硬盘号   -> 0: 主硬盘  1: 从硬盘
;     第 6 位: 选择读写模式 -> 0: CHS     1: LBA
;
; 3. 在 0x1f7写入 0x20(表示读硬盘) / 0x30(表示写硬盘)
; 4. 等待硬盘就绪, 通过 0x1f7 端口查询硬盘状态
;    [0x1f7] -> [BSY|   |   |   |DRQ|   |   |   ]
;                 7   6   5   4   3   2   1   0
;     第 7 位 -> 0: 硬盘闲  1: 硬盘忙
;     第 3 位 -> 0: 未就绪  1: 已就绪
; 5. 一切就绪后, 在 0x1f0 端口(16位)读取数据(1 word)

NUL equ 0x00
SETCHAR equ 0x07
HDDPORT equ 0x1f0               ; 硬盘扇区起始端口号
VIDEOMEM equ 0xb800
STRINGLEN equ 0xffff
section code align=16 vstart=0x7c00

main:
    mov si, [READSTART]         ; 通过两个 16 位寄存器保存 28 位扇区号
    mov cx, [READSTART+0x02]    ; si 保存低 16 位, cx 保存高 12 位 
    mov al, [SECTORNUM]         ; 保存读取扇区数, 端口是 8 位寄存器, 所以用 al
    push ax                     ; 后面还会用到 ax , 先 push 一个副本

    mov ax, [DESTMEN]           ; 将物理地址转化为逻辑地址
    mov dx, [DESTMEN+0x02]      ; 高16位存在 dx, 低16位存在 ax
    mov bx, 16                  ; 因为段地址必须是 16 字节对齐的
    div bx                      ; 所以 dx:ax / bx, 商存在ax里, 余数在 dx 里
                                ; 从而刚好满足: 段地址×16 + 偏移地址 = 物理地址
    mov ds, ax                  ; 将段地址寄存器 ds 的值设置为 ax 中的值
    xor di, di                  ; 将偏移地址设置为 0
    pop ax                      ; 将 ax 还原为开始的样子, 这样 al 中才是读取扇区数, 虽然可以通过改变顺序避免这些入栈出栈的操作

    call ReadHDD
    xor si, si
    call PrintString
    jmp End

ReadHDD:        ; 参数: al: 读取扇区数
                ;       si: 逻辑号低16位 
                ;       cx: 逻辑号高12位
                ;       ds: 读取出的数据存放在内存的段地址
                ;       di: 读取出的数据存放在内存的偏移地址
    .setup:
        push ax ; 保存现场
        push bx
        push cx
        push dx

    .sendsignal:
        mov dx, HDDPORT+2
        out dx, al          ; 端口是 8 位寄存器, 所以用 al

        mov ax, si          ; 将逻辑号的 0 ~ 15 位读入 ax 中

        mov dx, HDDPORT+3   ; 写入 7 ~ 0 位
        out dx, al

        mov dx, HDDPORT+4   ; 写入 15 ~ 8 位
        mov al, ah          ; 将 15 ~ 8 位 从 ah 复制到 al 中
        out dx, al

        mov ax, cx          ; 将逻辑号的 27 ~ 16 位读入 ax 中 
                            ; 实际读入到 31 位

        mov dx, HDDPORT+5   ; 写入 23 ~ 16 位
        out dx, al

        mov dx, HDDPORT+6   ; 写入 27 ~ 24 位, 以及硬盘参数
        mov al, ah          ; 将 25 ~ 31 位 从 ah 复制到 al 中 .... [....]
        mov ah, 0xe0        ; 0xe0 -> [1110] 0000
        or al, ah           ; 将 al 和 ah 融合在一起 [1110] [....], 存在 al 中
        out dx, al          ; 将 al 输出

        mov dx, HDDPORT+7   ; 在 0x1f7 端口中写入 0x20 表示读盘
        mov al, 0x20
        out dx, al

    .waits:
        in al, dx           ; 读取 0x1f7 端口, 得到硬盘的状态字节
        and al, 0x88        ; 0x88 -> 1000 1000 除了 3、7位的其它位置为 0
        cmp al, 0x08        ; 0x08 -> 0000 1000 当第 7 位为 0 , 第 3 位为 1 时, 就可以读盘了 (cmp 会将两个操作数相减)
        jnz .waits          ; 不等的话就继续等待, jump if zero flag is unset
    
    .readsetup:
        mov dx, HDDPORT     ; 设置读取数据的端口 0x1f0
        mov cx, 256         ; 设置读取次数: 一个扇区 512 个字节, 读 256 次

    .readword:              ; 读数据, 一次读 2 个字节 (0x1f0是16位端口)
        in ax, dx           ; 使用 in 指令, 将数据读取到 ax 寄存器
        mov [ds:di], ax     ; 将数据保存到 ds:di 指向的内存单元
        add di, 2           ; 将偏移地址 +2 (一次写入 2 个字节)         
        loop .readword      ; 循环 256 次, 读取一个扇区的数据

    .return:
        pop dx              ; 还原现场
        pop cx
        pop bx
        pop ax

        ret

PrintString:
    .setup:
        push ax ; 保存现场
        push bx
        push cx
        push dx

        mov ax, VIDEOMEM ; 显存起始地址
        mov es, ax
        xor di, di        ; 将 di 设置为 0x0000

        mov bh, SETCHAR   ; 设置字符属性
        mov cx, STRINGLEN ; 设置循环次数

    .print:
        mov bl, [ds:si] ; 读取字符
        inc si
        mov [es:di], bl ; 输出字符
        inc di
        mov [es:di], bh ; 输出字符属性
        inc di
        or bl, NUL     ; 判断是否遇到终结符
        jz .return
        loop .print
    
    .return:
        pop dx  ; 还原现场
        pop cx
        pop bx
        pop ax

        ret

READSTART dd 10     ; 读取起始扇区号, 4 个字节(32位), 实际上只要 28 位
SECTORNUM db 1      ; 读取扇区数, 1 个字节
DESTMEN dd 0x10000  ; 数据保存到内存的位置的起始位置, 4 个字节, 物理地址

End:
    jmp End
    times 510-($-$$) db 0
    db 0x55, 0xaa