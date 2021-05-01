; adc -> add with carry
;     = 被加数 + 加数 + CF
; sbb -> sub with carry
;     = 被减数 - 减数 - CF

; 将两个32的数字相加
; 一个32位数字 -> 两个16位寄存器储存

; eg: 0x 0001   f000  +  0x 0010   1000
;       [ BX ] [ AX ]      [ DX ] [ CX ]

mov bx, 0x0001
mov ax, 0xf000

mov dx, 0x0010
mov cx, 0x1000

;    0001        f000 
;   [ BX ]      [ AX ]
;    0010        1000
;   [ DX ]      [ CX ]
; 将低位和高位数字分别相加, 又因为低位相加前 CF = 0
; 所以低位相加时可以不用 adc
add ax, cx
adc bx, dx
; 相加的结果: sum = bx:ax

; 减法同理

jmp $
times 510-($-$$) db 0
db 0x55, 0xaa