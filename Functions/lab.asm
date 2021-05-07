section .data
    sscanf_fmt: db "%8s %ld %ld",0

section .bss
    input_buffer: resb 100

section .text
  global main
  extern sscanf

main:       push  rbp
            mov   rbp, rsp
            sub   rsp, 32              ; 3 x quadwords (8 bytes) + 8 bytes for stack alignment    

            xor   rax, rax
            mov   qword [rbp-8], 1
            mov   qword [rbp-16], 2
            mov   qword [rbp-24], 3 
            mov   qword [rbp-32], 4

.loop:      lea   rdi, [rbp-8]        
            lea   rsi, [rbp-16]       
            lea   rdx, [rbp-24]       

            sub   rsp, 8

            xor   rbx, rbx
            mov   [rbp-8], rbx         ; zeroing local variable to get rid of the garbage that was along
                                       ; the input that was received with scanf (check this and checks vals)
            push  rbp
            push  rsp
            push  rdi
            push  rsi
            push  rdx

            xor   rax, rax
            xor   rbx, rbx

.L1         cmp   rax, 100
            jz    .end_L1
            mov   [input_buffer+rax], bl   
            inc   rax
            jmp   .L1   
            
.end_L1:    mov   rax, 0
            mov   rdi, 0               
            lea   rsi, [input_buffer]  
            mov   rdx, 100           
            syscall

            pop   r9
            pop   r8
            pop   rcx
            pop   rsp
            pop   rbp

            lea   rdi, [input_buffer]  
            lea   rsi, [sscanf_fmt]
            lea   rdx, [rbp-8]
            push  rsp
            call  sscanf         
            pop   rsp

            add   rsp, 8            

            add   rsp, 32
            leave
            xor   rax, rax
            ret