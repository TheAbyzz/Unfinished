; command line arguments
; rdi = number of command line arguments e.g. ./a.out 1 2 3, rdi = 4 including "a.out"
; rsi = pointer to the first argument string "a.out"
; rsi+8 = pointer to the second argument string "2"
; and so on...

section .data
	fmt: db "%s",0x0a,0

section .text
	global main
	extern printf

main: push rbp
      mov  rbp, rsp

      mov  rbx, rdi
      mov  r12, rsi

      xor  r13, r13

.L1:  cmp  r13, rbx
      jz   .end
      lea  rdi, [fmt]
      mov  rsi, [r12]
      xor  rax, rax
      call printf
      add  r12, 8
      inc  r13
      jmp  .L1

.end: xor  rax, rax
      leave
      ret
