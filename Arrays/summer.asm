; "64 Bit Intel Assembly Language Programming for Linux"

; p.114 exercise 5.

; Write an assembly program to read a sequence of integers using
; scanf and determine if the first number entered can be formed
; as a sum of some of the other numbers and print a solution if it
; exists. You can assume that there will be no more than 20 numbers.
; Suppose the numbers are 20, 12, 6, 3 , and 5. Then 20 = 12 + 3 + 5.
; Suppose the numbers are 25, 1 1 , 17, 3. In t his case there are no
; solutions.

; Obs! The program handles only signed 4 byte values. Atol() returns a
; a 8 byte value but qsort() handles only 4 byte values. When 54fkg is
; supplied to atol(), 54 is returned, so beware of that. 

; rbp, rbx, r12, r13, r14, r15 <-- registers which are saved
; check all programs with malloc (only in arrays)
; rdi, rsi, rdx, rcx, r8, r9.
;
; The processing function is missing!

section .data
      fmt: db "%d",0x0a,0

section .bss
      buf_ptr: resq 1
      buf_siz: resq 1

section .text
	global main
	extern malloc
      extern realloc
	extern free
	extern atol
	extern qsort
	extern printf

main: push  rbp
      mov   rbp, rsp
      sub   rsp, 128

      xor   rbx, rbx

.L1:  mov   rax, 0
      mov   rdi, 0
      lea   rsi, [rbp-100]
      mov   rdx, 100
      syscall
      cmp   rax, 1
      jz    .ret              

      lea   rdi, [rbp-100]
      mov   rsi, rax
      lea   rdx, [rbp-108]
      call  extr
      
      mov   rbx, rax
      mov   rax, [rbp-108]
      cmp   rax, 0
      jz    .nva

      mov   rdi, rbx
      mov   rsi, rax
      mov   rdx, 4
      mov   rcx, cmp            
      call  qsort 

.nva: jmp   .L1

.ret: mov   rdi, rbx
      call  free
      add   rsp, 128    
      xor   rax, rax
      leave
      ret

cmp:  mov   ecx, [rdi]
      mov   edx, [rsi]
      cmp   ecx, edx
      setg  sil
      movzx eax, sil
      cmp   edx, ecx
      setg  r8b
      movzx r9d, r8b
      sub   eax, r9d     
      ret

extr: push  rbx
      push  r12
      push  r13
      push  r14
      push  r15
      push  rdx 
      
      mov   rbx, rdi
      mov   r12, rsi
      xor   r13, r13
      mov   byte [rbx+r12], 32
      mov   r14, [buf_ptr] 
      mov   r15, [buf_siz]   
      cmp   r14, 0
      jnz   .L1
      
      mov   rdi, 80         ; 20 * double words        
      call  malloc
      cmp   rax, 0
      jz    .ret
      mov   r14, rax
      mov   r15, 80
      mov   [buf_ptr], r14
      mov   [buf_siz], r15

.L1:  mov   rax, 32
      mov   rdi, rbx
      mov   rcx, r12
      repne scasb      
      mov   r12, rcx 

      xor   rdi, rbx
      xor   rbx, rdi
      xor   rdi, rbx
      call  atol
      cmp   rax, 0     
      jz    .pos
      
      mov   [r14], eax 
      add   r14, 4                
      inc   r13
      sub   r15, 4
      cmp   r15, 0
      jnz   .pos

      mov   rdi, [buf_ptr]
      mov   r14, [buf_siz]
      mov   rsi, 80
      add   rsi, r14          
      mov   [buf_siz], rsi
      call  realloc
      cmp   rax, 0
      cmovz r13, rax
      jz    .ret
      mov   [buf_ptr], rax
      add   r14, rax

.pos: cmp   r12, 0
      jnz   .L1

.ret: pop   rdx
      mov   [rdx], r13           
      mov   rax, [buf_ptr]

      pop   r15
      pop   r14
      pop   r13
      pop   r12
      pop   rbx

      ret

; proc(arr_start_adrss, arr_length)

proc: push  rbx
      push  r12
      push  r13
      push  r14
      push  r15

      mov   rbx, rdi
      mov   r12, rsi
      mov   r13, 1

.L1:  cmp   r13, r12
      jz    .end
      



.end: pop   r15
      pop   r14
      pop   r13
      pop   r12
      pop   rbx
      ret
