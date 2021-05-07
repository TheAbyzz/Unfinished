; I'd problems with the extern stdin so I went with the syscall for reading 1 line at a time.
; The syscall returns the nr of given charater + the newline character if there's room for it.

section .text
	global _start

_start: push rbp
        mov  rbp, rsp
        sub  rsp, 128

.L1:    mov  rax, 0
        mov  rdi, 0
        lea  rsi, [rbp-100]
        mov  rdx, 100
        syscall
        cmp  rax, 1
        jz   .ret

        dec  rax                ; remember if there's room for newline character (recheck this)
        
        lea  rdi, [rbp-100]
        mov  rsi, rax
        call adlr23

.ret:   add  rsp, 128
        xor  rax, rax
        leave
        ret

adlr23: push  rbp
        push  rbx
        push  r12
        push  r13
        push  r14
        push  r15

        mov   rbp, 1
        xor   rbx, rbx
        xor   r12, r12
        mov   r13, 65521

.L1:    cmp   r12, rsi
        jz    .ret
        movzx r14, byte [rdi+12]
        add   rbp, r14
        mov   rax, rbp
        xor   rdx, rdx
        div   r13
        mov   rbp, rdx
        add   rbx, rbp
        mov   rax, rbx
        xor   rdx, rdx
        div   r13
        mov   rbx, rdx
        inc   r12
        jmp   .L1

.ret:   shl   rbx, 16
        or    rbx, rbp
        mov   rax, rbx    

        pop  r15
        pop  r14
        pop  r13
        pop  r12
        pop  rbx
        pop  rbp
        ret