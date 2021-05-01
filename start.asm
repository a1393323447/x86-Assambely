mov ax, 0xb800 ; 显存起始地址
mov ds, ax     ; 指定数据段的基准地址, 下面的地址都是相对于基准地址的偏移量
               ; 在寄存器的 mov 可以不加位宽修饰符, 因为 寄存器 的位宽都是固定的
               ; 但一定要保证 位宽 一致!

mov byte [0x00], '0' ; 显卡使用默认图像模式
mov byte [0x02], '1' ; 显示(ASCII)字符的方法: 
mov byte [0x04], '2' ; 往显存中发送两个连续的字节数据
mov byte [0x06], '3' ; [ASCII码] [属性字节]
mov byte [0x08], '4' ; 又因为计算机默认使用白底
mov byte [0x0a], '5' ; 所以可以只发送[ASCII码]
mov byte [0x0c], '6' ; 但必须把属性字节空出来
mov byte [0x0e], '7' ; byte: 位宽, mov 的 目的操作数 和 源操作数 的位宽必须一致
mov byte [0x10], '8' ; byte:  1 字节
mov byte [0x12], '9' ; word:  2 字节
mov byte [0x14], 'A' ; dword: 4 字节
mov byte [0x16], 'B' ; qword: 8 字节
mov byte [0x18], 'C'
mov byte [0x1a], 'D'
mov byte [0x1c], 'E'
mov byte [0x1e], 'a'
mov byte [0x20], 'b'
mov byte [0x22], 'c'
mov byte [0x24], 'd'
mov byte [0x26], 'e'

; IP: 指令寄存器, 无法被直接修改. 可以通过 jmp 指令修改

jmp $ ; jmp $: 跳转到 jmp 所在的位置, 目的是通过 $ 标定 jmp 的位置
 
times 510-($-$$) db 0 ; $$: 表示程序的起始地址, times: 多次执行, db: 填充数据

; 上一行代码的作用: MBR分区共 512 个字节, 减去两个字节的标志位, 还有 510 个字节
; $-$$ 得出程序的字节数, 510 - ($-$$): 就是没有使用的空间的大小, 即要填的 0 的个数

db 0x55, 0xaa ; MBR分区最后的标志位
