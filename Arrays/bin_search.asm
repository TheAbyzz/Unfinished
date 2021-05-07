section .text
	global main
	extern atol
	extern malloc
	extern free
	extern rand
	extern qsort
	extern printf

default rel

main: push rbp
      mov  rbp, rsp
      sub  rsp, 16
      xor  r12, r12
      cmp  rdi, 2
      jnz  .end

      add  rsi, 8
      mov  rdi, [rsi]
      mov  rbx, rdi              ; rbx = nr of elements in array
      call [atol WRT ..got]
      imul rax, 4                ; any checks??
      
      mov  rdi, rax
      call [malloc WRT ..got]
      cmp  rax, 0
      jz   .end
      mov  r12, rax              ; r12 = pointer to array

      mov  r13w, 1000 
      xor  r14, r14
.L1:  xor  rax, rax
      call [rand WRT ..got]      ; rand() returns a 4 byte value in [0,2147483647]
      mov  edx, 0xffff0000
      and  edx, eax
      shr  edx, 16
      and  eax, 0xffff
      div  r13w                  ; arithmetic exception
      
      mov  [r12+r14*4], dx
      inc  r14
      cmp  r14, rbx
      jnz  .L1

      mov  rdi, r12
      mov  rsi, rbx
      mov  rdx, 4
      lea  rcx, [cmp]
      call [qsort WRT ..got]

.L2:  mov  rax, 0
      mov  rdi, 0
      lea  rdx, [rbp-11]   
      mov  rcx, 10                ; check video on youtube, 10 or 11, 11 is used in video
      syscall
      cmp  rax, 1
      jz   .end

      lea   rdi, [rbp-11]
      mov   rcx, 10         
      mov   al, 10
      repne scasb

      mov   rax, 11
      sub   rax, rcx
      mov   byte [rbp-11+rax], 32

      lea   rdi, [rbp-11]
      call  [atol WRT ..got]

      mov   rdi, r12
      mov   rsi, rbx
      mov   rdx, rax
      call  bin

      ; we the index 

      ;lea  rdi, [fmt]
      ;lea  rsi, [msg1 or msg2]
      xor  rax, rax
      call printf

      jmp  .L1

.end: mov  rdi, r12
      call [free WRT ..got]
      xor  rax, rax
      leave
      ret

cmp:  

;bin(start_addr, length, key)           ; length is not a multiple of 4, we need to multiply before
                                        ; carrying on
bin:  mov   rdx, 0xffffffff00000000
      and   rdx, rsi
      shr   rdx, 32
      mov   eax, 0xffffffff
      and   eax, esi  
      mov   ebx, 2
      div   ebx
      and   rax, 0xffffffff

      xor   rcx, rcx
      mov   ebx, [rdi+rax*4]
      cmp   ebx, edx
      cmovg rcx, rax
      mov   rsi, rax
      setz  al
      movsx eax, al          
      jz    .ret

      cmp   rax, 0           
      setz  al
      movsx eax, al
      jz    .ret

      add   rcx, rdi
      call  bin

.ret  ret