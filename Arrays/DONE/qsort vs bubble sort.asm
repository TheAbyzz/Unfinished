; Write 2 test programs: one to sort an array of random 4 byte in­
; tegers using bubble sort and a second program to sort an array of
; random 4 bytes integers using the qsort function from the C library.
; Your program should use the C library function atol to convert a
; number supplied on the command line from ASCII to long. This
; number is the size of the array ( number of 4 byte integers ) . Then
; your program can allocate the array using malloc and fill the array
; using random. You call qsort like this
; qsort ( array , n , 4 , compare ) ;

; how to supply rand() with a seed

section .data
	array_el_fmt: db "%d ",0
	newline_fmt: db 0x0a	

section .text
	global main
	extern atol
	extern malloc
	extern free
	extern rand
	extern qsort
   extern bubble_sort
	extern printf

main:    push rbp
         mov  rbp, rsp

         mov  rax, rdi
         cmp  rax, 2
         jnz  .err

         mov  rax, rsi
         add  rax, 8
         mov  rdi, [rax]
         call atol WRT ..plt
         cmp  rax, 0
         jz   .err
         mov  rbx, rax
         
         mov  rdi, 4
         imul rdi, rax
         call malloc WRT ..plt
         cmp  rax, 0
         jz   .err
         mov  r12, rax

         xor  r13, r13

.L1:     cmp  r13, rbx
         jz   .end_L1
         xor  rax, rax
         call rand WRT ..plt
         mov  [r12+4*r13], eax
         inc  r13
         jmp  .L1

.end_L1: mov  rdi, r12
         mov  rsi, rbx
         call print                      

         mov  rdi, r12
         mov  rsi, rbx
         mov  rdx, 4
         lea  rcx, [rel compare]
         call qsort WRT ..plt

         ;mov  rdi, r12
         ;mov  rsi, rbx
         ;call bubble_sort                            

         mov  rdi, r12
         mov  rsi, rbx
         call print                   

         mov  rdi, r12
         call free WRT ..plt

.err:    xor  rax, rax
         leave
         ret

compare: mov  rax, [rdi]      
         sub  rax, [rsi]
         ret

print:   push rbx
         push r12

         mov  rbx, rdi
         mov  r12, rsi
         xor  rcx, rcx

.L1:     cmp  rcx, r12
         jz   .end_L1
         lea  rdi, [rel array_el_fmt]
         mov  esi, [rbx+rcx*4]           
         xor  rax, rax
         push rcx
         call printf WRT ..plt
         pop  rcx
         inc  rcx
         jmp  .L1

.end_L1: lea  rdi, [rel newline_fmt]
         xor  rax, rax
         call printf WRT ..plt

         pop  r12
         pop  rbx
         xor  rax, rax
         ret