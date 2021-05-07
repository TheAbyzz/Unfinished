section .data
    ff: db "%ld %lu"

section .bss
    a: resq 1
    b: resq 1

section .text
    global main
    extern scanf

main: push  rax
      lea   rdi, [ff]
      lea   rsi, [a]
      lea   rdx, [b]
      xor   rax, rax
      call  scanf
      pop   rax
      mov   rax, [a]
      mov   rbx, [b]
      xor   rax, rax
      ret 

; 18446744073709551616 18446744073709551616


; ld -> 18446744073709551616 (max unsigned 64 bit +1) ->  9223372036854775807 (max signed 64 bit)
; lu -> 18446744073709551616 (max unsigned 64 bit +1) -> 18446744073709551615 (max unsigned 64 bit)
; ld ->  9223372036854775808 (max signed 64 bit +1)   ->  9223372036854775807 (max signed 64 bit)
; lu ->  9223372036854775808 (max signed 64 bit +1)   -> -9223372036854775808 (max signed 64 bit +1)
; ld -> -9223372036854775809 (min signed 64 bit -1)   ->  9223372036854775808 (min signed 64 bit)
; lu -> -9223372036854775809 (min signed 64 bit -1)   ->  9223372036854775807 (max signed 64 bit)

; ld -> 18446744073709551617 (max unsigned 64 bit +2) ->  9223372036854775807 (max signed 64 bit)
; lu -> 18446744073709551617 (max unsigned 64 bit +2) -> 18446744073709551615 (max unsigned 64 bit)
; ld ->  9223372036854775809 (max signed 64 bit +2)   ->  9223372036854775807 (max signed 64 bit)
; lu ->  9223372036854775809 (max signed 64 bit +2)   ->  9223372036854775809 (max signed 64 bit +1)
; ld -> -9223372036854775810 (min signed 64 bit -2)   -> -9223372036854775808 (min signed 64 bit)
; lu -> -9223372036854775810 (min signed 64 bit -2)   ->  9223372036854775806 (max signed 64 bit)



; hd ->                65536 (max unsigned 16 bit +1) ->            0 (zero)
; hu ->                65536 (max unsigned 16 bit +1) ->            0 (zero)
; hd ->                32768 (max signed 16 bit +1)   ->       -32768 (max signed 16 bit +1/min signed 16 bit) wraps
; hu ->                32768 (max signed 16 bit +1)   ->        32768 (max signed 16 bit +1/min signed 16 bit) wraps
; hd ->               -32769 (min signed 16 bit -1)   ->        32767 (max signed 16 bit) wraps
; hu                  -32769 (min signed 16 bit -1)   ->        32767 (max signed 16 bit) wraps

; check if it wraps around 18446744073709551616 18446744073709551616

; -9223372036854775809 -9223372036854775809