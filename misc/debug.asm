mov ax, 0x7c00
mov ds, ax

mov bx, 0x353637        ; mov bx, 0x3637
mov byte [0xf1], 'H'    ; 
mov byte [0xf2], 0x3839
jmp $                   ; 等同于 this_line: jmp this_line
times 510-($-$$) db 0
db 0x55, 0xaa

; b addr [break at addr]
; c [continu]
; s [excute next commond]
; xp /nuf addr [n: num, u: unit, f: format]
; u: b [1 byte], h [2 bytes], w [4 bytes], g [8 bytes]
; f: b [binary], d [decimal], h [hexadecimal]