; 拓展 int 0x13 支持通过 LBA 方式读取 2^73 字节的磁盘

;只有一个段，从0x7c00开始
section Initial vstart=0x7c00
;程序开始前的设置，先把段寄存器都置为0，后续所有地址都是相对0x00000的偏移
ZeroTheSegmentRegister:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
;栈空间位于0x7c00及往前的空间，栈顶在0x7c00
SetupTheStackPointer:
    mov sp, 0x7c00
Start:
    mov si, BootLoaderStart
    call PrintString
;查看是否支持拓展int 13h
CheckInt13:
    mov ah, 0x41    ; ah: 选择功能, 0x41为检查 0x42为读取
    mov bx, 0x55aa  ; 0x55 0xaa 魔法数
    mov dl, 0x80    ; dl: 选择硬盘 0x80: 主盘
    int 0x13        ; 调用中断
    cmp bx, 0xaa55  ; 如果 bx 中依然为 0x55aa, 则说明本机BIOS支持拓展0x13中断
    mov byte [ShitHappens+0x06], 0x31 ; 自定义的错误代码, 1 说明不支持拓展中断
    jnz BootLoaderEnd
;寻找MBR分区表中的活动分区，看分区项第一个字节是否为0x80，最多4个分区
SeekTheActivePartition:
    ; MBR分区表之前有 446 个字节
    ; 分区表位于0x7c00+446=0x7c00+0x1be=0x7dbe的位置，使用di作为基地址
    mov di, 0x7dbe
    mov cx, 4        ; 循环 4 次以查找四个分区
    isActivePartition:
        mov bl, [di] ; 读取每个分区入口的第一个字节
        cmp bl, 0x80 ; 检查是否是活动分区
        ; 如果是则说明找到了，使用 jmp if equel 指令跳转继续
        je ActivePartitionFound
        ; 如果没找到，则继续寻找下一个分区项，每个分区入口有 16 个字节, si+16
        add di, 16
        loop isActivePartition
    ActivePartitionNotFound:
        mov byte [ShitHappens+0x06], 0x32 ; 找不到活动分区 错误码 2
        jmp BootLoaderEnd
; 找到活动分区后，di目前就是活动分区项的首地址
ActivePartitionFound:
    mov si, PartitionFound ; 输出提示信息
    call PrintString
    ; ebx 保存活动分区的入口地址
    mov ebx, [di+8]
    mov dword [BlockLow], ebx ; DiskAddressPacket 的数据成员
    ; 目标内存起始地址
    mov word [BufferOffset], 0x7e00 ; ... BootLoader: 0x7c00 ~ 0x7dff, 下一个空闲位置为 0x7e00
    mov byte [BlockCount], 1 ; 读取 1 个块
    ; 读取第一个扇区
    call ReadDisk
GetFirstFat:
; 计算 FAT表 FAT1 的起始块号（起始扇区号）
    mov di, 0x7e00      ; 分区从硬盘读到内存后的起始地址 
    ; ebx目前为保留扇区数
    xor ebx, ebx
    mov bx, [di+0x0e]   ; 分区前已使用块数 [di+0x0e]
    ; FirstFat 起始扇区号 = 隐藏扇区 + 保留扇区
    mov eax, [di+0x1c]  ; FAT 保留块数 [di+0x1c]
    add ebx, eax        ; FAT1 的起始块号 = 分区前已使用块数 + FAT 保留块数
; 获取 FAT 数据区起始区扇区号
; FAT 数据区起始区扇区号 = FAT1 的起始块号 + FAT 表所占的块数
GetDataAreaBase:
    mov eax, [di+0x24]  ; 每一个 FAT 表所占的块数
    xor cx, cx          ; cx: 循环次数
    mov cl, [di+0x10]   ; FAT 表的数量
    AddFatSize:
        add ebx, eax    ; 累加
        loop AddFatSize
; 读取数据区 8个扇区/1个簇
ReadRootDirectory:
    ; 当前空闲内存起始地址 = 0x7e00 + 0x0200(一个块 512 字节) = 0x8000
    mov [BlockLow], ebx ; 设置读取的磁盘起始块号
    mov word [BufferOffset], 0x8000
    mov di, 0x8000
    mov byte [BlockCount], 8    ; 读取 8 个块 （8个扇区/1个簇）128 个文件条目
    call ReadDisk
    mov byte [ShitHappens+0x06], 0x34
SeekTheInitialBin:
; 在读取出的文件条目中寻找 INITIAL.BIN 文件
    cmp dword [di], 'INIT'
    jne nextFile
    cmp dword [di+4], 'IAL '
    jne nextFile
    cmp dword [di+8], 'BIN '
    jne nextFile
    jmp InitialBinFound         ; 找到就跳到 InitialBinFound
    nextFile:
    ; 0x9000 = 0x8000 + 8 * 0x0200 即当前空闲内存的起始位置
        cmp di, 0x9000          ; 如果已经读到空闲内存, 还没找到 INITIAL.BIN,
        ja BootLoaderEnd        ; 如果是跳到 BootLoaderEnd
        add di, 32              ; di + 32 指向下一个文件条目的起始地址
        jmp SeekTheInitialBin   ; 继续寻找

InitialBinFound:
; 找到 INITIAL.BIN 后, 读取
    mov si, InitialFound
    call PrintString
    ;获取文件长度  dx:ax
    mov ax, [di+0x1c]
    mov dx, [di+0x1e]
    ;文件长度是字节为单位的，需要先除以512得到扇区数
    ; ax: 商, dx: 余数
    mov cx, 512
    div cx
    ;如果余数不为0，则需要多读一个扇区
    cmp dx, 0
    je NoRemainder
    ;ax是要读取的扇区数
    inc ax
    mov [BlockCount], ax
    NoRemainder:
        ;文件起始簇号，也是转为扇区号，乘以8即可
        mov ax, [di+0x1a]
        sub ax, 2
        mov cx, 8
        mul cx
        ;现在文件起始扇区号存在dx:ax，直接保存到ebx，这个起始是相对于DataBase 0x32,72
        ;所以待会计算真正的起始扇区号还需要加上DataBase
        and eax, 0x0000ffff
        add ebx, eax
        mov ax, dx
        shl eax, 16
        add ebx, eax
        mov [BlockLow], ebx
        mov word [BufferOffset], 0x9000
        mov di, 0x9000
        call ReadDisk
        ;跳转到Initial.bin继续执行
        mov si, GotoInitial
        call PrintString
        jmp di
ReadDisk:
    mov ah, 0x42 ; 0x42: 读取
    mov dl, 0x80 ; 0x80: 主盘
    mov si, DiskAddressPacket ; DiskAddressPacket 一个16字节数据结构
    int 0x13     ; 调用中断
    test ah, ah  ; test 将两个操作数进行逻辑与运算，并根据运算结果设置相关的标志位
    mov byte [ShitHappens+0x06], 0x33 ; 错误代码 3
    jnz BootLoaderEnd ; 标志位不为 0
    ret

; 打印以0x0a结尾的字符串
; 参数: si 字符串的起始地址
PrintString:
    push ax
    push cx
    push si
    mov cx, 512 ; 限制最大可打印字符数为 512
    PrintChar:
        mov al, [si]
        mov ah, 0x0e
        int 0x10
        cmp byte [si], 0x0a
        je Return
        inc si
        loop PrintChar
    Return:
        pop si
        pop cx
        pop ax
        ret

BootLoaderEnd:
    mov si, ShitHappens
    call PrintString
    hlt
;使用拓展int 13h读取硬盘的结构体DAP
DiskAddressPacket:
    ;包大小，目前恒等于16/0x10，0x00
    PackSize      db 0x10
    ;保留字节，恒等于0，0x01
    Reserved      db 0
    ;要读取的数据块个数，0x02
    BlockCount    dw 0
    ;目标内存地址的偏移，0x04
    BufferOffset  dw 0
    ;目标内存地址的段，让它等于0，0x06
    BufferSegment dw 0
    ;磁盘的起始块号
    ;磁盘起始绝对地址，扇区为单位，这是低字节部分，0x08
    BlockLow      dd 0
    ;这是高字节部分，0x0c
    BlockHigh     dd 0
ImportantTips:
  
    BootLoaderStart   db 'Start Booting!'
                        db 0x0d, 0x0a
    PartitionFound    db 'Get Partition!'
                        db 0x0d, 0x0a
    InitialFound      db 'Get Initial!'
                        db 0x0d, 0x0a
    GotoInitial       db 'Go to Initial!'
                        db 0x0d, 0x0a
    ShitHappens       db 'Error 0, Shit happens, check your code!'
                        db 0x0d, 0x0a
;结束为止
  times 446-($-$$) db 0
