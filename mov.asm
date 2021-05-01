; 根据报错信息, 学习 mov 指令
mov 0xb700, 0xb800 ; 两个都是立即数
mov [0x01], 0xb800 ; 没有给出位宽

mov byte [0x01], 0xb800 ; warning: 位宽不够
mov word [0x01], 0xb800
mov [0x01], [0x02] ; 两个都是内存单元

mov ax, [0x02]
mov [0x03], ax
mov ds, [0x05]
mov [0x04], ds

mov ax, bx
mov cx, dl ; 位宽不同

mov cs, ds ; 两个都是段寄存器