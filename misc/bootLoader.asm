; bootLoader 的任务
; 1. 读取第一个扇区(我们自己决定的), 获取 program 的各项参数
; ------------------------------
; 2. 根据程序的大小, 读取剩余扇区 |  暂时先从简单的做起, 还没有实现
; ------------------------------
; 3. 对程序段地址以及入口重定位
; 4. 跳转到程序的入口地址

HDDPORT equ 0x1f0

section code align=16 vstart=0x7c00
main:
    mov si, [READSTART]
    mov cx, [READSTART+2]
    mov al, [SECTORNUM]
    push ax

    mov ax, [DESTMEN]
    mov dx, [DESTMEN+0x02]
    mov bx, 16
    div bx

    mov ds, ax          ; 设置数据段段地址为读出的数据所在的地址------
    xor di, di          ;                                         |
    pop ax              ;                                         |
                        ;                                         |
    call ReadHDD        ; 1. 读取 1 号扇区                         |
ReadAll:                ; 2. 读取 Size, 并根据 Size 读取剩下的程序. |
    mov ax, [0x00]      ; 读取 Size                               |
    shr ax, 9           ; 右移 9 位 -> 除以 512                    |
    cmp al, 0x00        ; al: 商                                  |
    jz  RestSegment     ; al == 0 -> Size <= max(一个扇区)         |
    ; mov ah, al          ; 设置 ReadHDD 的参数                      |
    mov bx, 0x0001      ; 扇区号 + 1                               |
    add si, bx          ;                                         |
    mov bx, 0x0000      ;                                         |
    adc cx, bx          ;                                         |
    call ReadHDD        ; 读盘                                     |
RestSegment:            ; 3. 地址重定位                             |
    mov bx, 0x04        ; 将第一个段地址相对于head的偏移地址放入 bx   |        
    mov cl, [0x10]      ; 这时候的偏移是相对于段地址的偏移         <--
                        ; [0x10] -> SegNum
    .reset:             
        mov ax, [bx]            ; 取出一个段地址, 高位存放在 dx, 低位存放在 ax
        mov dx, [bx+2]          ; 一个段地址 4 个字节
        add ax, [cs:DESTMEN]    ; 由于上面改变了 ds 的值, 所以要正确找到 [DESTMEN] 就必须要用 [cs:DESTMEN] / [es:...] / [ss:...] (详见 test.asm)
        adc dx, [cs:DESTMEN+2]  ; 将段地址加上实际物理地址(4B, 分两部分加)

        mov si, 16              ; 段地址 16 字节对齐
        div si
        mov [bx], ax            ; 将重定位后的段地址写入
        add bx, 4               ; 一个段地址 4 个字节, +4 到下一个段地址的开头
        loop .reset
RestEntry:
    mov ax, [0x13]              ; 程序入口地址: 4B, 先取低 2B
    mov dx, [0x15]              ; 再取高 2B
    add ax, [cs:DESTMEN]        ; 重定位
    adc dx, [cs:DESTMEN+2]

    mov si, 16
    div si

    mov [0x13], ax      ; 写入

    jmp far [0x11]      ; far: 跳向远方 (跳转的位置不在 bootLoader 内), [0x11]: 程序起始地址

ReadHDD:                ; 参数: al: 读取扇区数
    .setup:             ;       si: 逻辑号低16位 
        push ax         ;       cx: 逻辑号高12位
        push bx         ;       ds: 读取出的数据存放在内存的段地址
        push cx         ;       di: 读取出的数据存放在内存的偏移地址
        push dx
        
    .sendsignal:
        mov dx, HDDPORT+2   ; 写入读取扇区数
        out dx, al

        mov ax, si          ; 读入低16位

        mov dx, HDDPORT+3   ; 写入7 ~ 0位
        out dx, al

        mov dx, HDDPORT+4   ; 写入 15 ~ 8 位
        mov al, ah
        out dx, al

        mov ax, cx          ; 读入高12位, 还有其它4位

        mov dx, HDDPORT+5   ; 写入 23 ~ 16 位
        out dx, al

        mov dx, HDDPORT+6   ; 写入 27 ~ 24 位, 及其它 4 位
        mov al, ah
        mov al, 0xe0
        or  al, ah
        out dx, al

        mov dx, HDDPORT+7   ; 写入读写模式: 0x20 (读硬盘)
        mov al, 0x20
        out dx, al

    .waits:                  ; 等待
        in al, dx    
        and al, 0x88        ; 只关心 3、7 位
        cmp al, 0x08
        jnz .waits          ; jump if zero flag is unset

    mov dx, HDDPORT         ; 设置端口号
    pop ax
    mov ah, 256
    mul ah
    mov cx, ax             ; 设置循环次数, 直接读取一个扇区

    .readword:
        in  ax, dx
        mov [ds:di], ax
        add di, 2
        ; or  al, 0x00
        ; jz  .return
        loop .readword

    .return:
        pop dx
        pop cx
        pop bx
        pop ax

        ret

READSTART dd 1
SECTORNUM db 1
DESTMEN dd 0x10000

End:
    jmp End
    times 510-($-$$) db 0
    db 0x55, 0xaa