; Write an assembly program to keep track of 10 sets of size 1000000.
; Your program should read accept the following commands: add,
; union, print and quit. The program should have a function to
; read the command string and determine which it is and return 0, 1 ,
; 2 or 3 depending on the string read. After reading add your program
; should read a set number from 0 to 9 and an element number from
; 0 to 999999 and insert the element into the proper set. You need
; to have a fuction to add an element to a set. After reading union
; your program should read 2 set numbers and make the first set be
; equal to the union of the 2 sets. You need a set union function.
; After reading print your program should print all the elements of
; the set. You can assume that the set has only a few elements. After
; reading quit your program should exit.
;
; Ok, so we are going to load the set numbers into unsigned bytes and validate the range
; and the values that go into the sets are going to be loaded into doublewords before being
; validated
;
; Here it's really important to use unsigned values because in a scenario where the given
; values exceeds the max unsigned value the max unsigned value will be used!!! what about negative values
;
; use correct sized variable in main and 64 bit variable in read_input (doesn't wrap around)
;
; NOT WORKING WITH PRINT EXPECTS 3 INPUTS!!! USE SYSCALL TO GET THE WHOLE INPUT LINE AND SSCANF AFTER THAT
;

; DOCUMENTATION
;
; segmentation fault with the inputs below, quit is not needed, program segment faults even program is designed to
; exit after taking the problematic input form the user (check out lab.asm)
;
; p(int[2])sets
; quit
; Segmentation fault (core dumped)         
;
; dfdf7373[4]40))()sets2#
; quit
; Segmentation fault (core dumped)
;
; ffeefefefeefhefhehefhf
; quit
; Segmentation fault (core dumped)

; https://zhu45.org/posts/2017/Jul/30/understanding-how-function-call-works/


section .data
	sscanf_fmt: db "%8s %ld %ld",0
      scanf_fmt: db "%99s",0
	printf_fmt: db "%lu ",0
	newline: db 0x0a,0
	commands: dq "add","union","print","quit","default"
	switch: dq add, union, print, quit, def

section .bss
	sets: resd 10000000  ; 10 * 1000000 * quadword (4 bytes)
      input_buffer: resb 100
      set_sizes: resd 10
      addr: resq 1

section .text
	global main
	extern sscanf
      extern scanf
	extern printf

main:       mov   [addr], rbp          ; extra
            push  rbp
            mov   rbp, rsp
            sub   rsp, 32              ; 3 x quadwords (8 bytes) + 8 bytes for stack alignment    

            xor   rax, rax
            mov   qword [rbp-8], 0     ; command
            mov   qword [rbp-16], 0    ; int 1
            mov   qword [rbp-24], 0    ; int 2
            mov   qword [rbp-32], 0    ; return value from syscall

.loop:      xor   rax, rax
            mov   [rbp-8], rax         

            xor   rbx, rbx

.L1:        cmp   rax, 100
            jz    .end_L1
            mov   [input_buffer+rax], bl   
            inc   rax
            jmp   .L1   
            
.end_L1:    mov   rax, 0
            mov   rdi, 0               
            lea   rsi, [input_buffer]  
            mov   rdx, 100                          
            syscall

            lea   rdi, [input_buffer]  
            lea   rsi, [sscanf_fmt]
            lea   rdx, [rbp-8]
            lea   rcx, [rbp-16]
            lea   r8, [rbp-24]
            call  sscanf         
            mov   [rbp-32], rax

            mov   rax, [rbp-8]
            lea   rdi, [commands]
            mov   rcx, 5
            repne scasq
            mov   rax, 4
            sub   rax, rcx
          
            mov   rdi, [rbp-16]
            mov   rsi, [rbp-24]
            mov   rdx, [rbp-32]        
            call  [switch+rax*8]
            cmp   rax, 0
            jz    .loop

            add   rsp, 32
            xor   rax, rax
            leave
            ret
            
add:        push  rbp
            mov   rbp, rsp

            cmp   rdx, 3
            jnz   .error

            cmp   rdi, 0
            js    .error
            cmp   rdi, 9
            jg    .error

            cmp   rsi, 0
            js    .error
            cmp   rsi, 999999
            jg    .error

            mov   r10, rdi
            imul  rdi, 4000000

            mov   rbx, rsi
            mov   eax, 0xffffffff
            cmp   esi, 0
            cmovz esi, eax
            
            mov   r9d, [sets+rdi+rbx*4]
            mov   ecx, 1
            xor   r8, r8
            cmp   r9d, esi
            cmovz ecx, r8d
            
            mov   r8d, [set_sizes+r10*4]
            add   r8d, ecx
            mov   [set_sizes+r10*4], r8d

            mov   [sets+rdi+rbx*4], esi

.error:     leave
            xor   rax, rax
            ret

union:      push  rbp
            mov   rbp, rsp

            xor   r9, r9

            cmp   rdx, 3
            jnz   .error

            cmp   rdi, 0
            js    .error
            cmp   rsi, 9
            jg   .error

            cmp   rsi, 0
            js    .error
            cmp   rsi, 9
            jg   .error

            mov   r8, rdi
            imul  rdi, 4000000
            imul  rsi, 4000000
            xor   rbx, rbx

.for:       cmp   rbx, 1000000
            jz    .error
            mov   ecx, [sets+rdi+rbx*4]
            mov   edx, [sets+rsi+rbx*4]
            cmp   ecx, edx
            jz    .skip
            cmp   ecx, 0
            jnz   .skip
            mov   [sets+rdi+rbx*4], edx
            inc   r9

.skip:      inc   rbx
            jmp   .for 

.error:     mov   r10d, [set_sizes+r8*4]
            add   r10d, r9d
            mov   [set_sizes+r8*4], r10d
            leave
            xor   rax, rax
            ret
            
print:      push  rbp
            mov   rbp, rsp

            cmp   rdx, 2
            jnz   .error

            cmp   rdi, 0
            js    .error
            cmp   rdi, 9
            jg    .error

            mov   eax, [set_sizes+rdi*4]
            cmp   eax, 0
            jz    .error

            mov   r12, rdi
            imul  r12, 4000000
            xor   rbx, rbx

            mov   esi, [sets+r12+rbx*4]
            cmp   esi, 0xffffffff
            jnz   .skip
            xor   esi, esi
            lea   rdi, [printf_fmt]
            xor   rax, rax
            call  printf
            
.skip:      inc   rbx

.for:       cmp   rbx, 1000000
            jz    .end
            mov   esi, [sets+r12+rbx*4]
            cmp   esi, 0
            jz    .empty            
            lea   rdi, [printf_fmt]
            xor   rax, rax
            call  printf

.empty:     inc   rbx
            jmp   .for

.end:       lea   rdi, [newline]
            xor   rax, rax
            call  printf

.error      leave
            xor   rax, rax
            ret

def:        push  rbp
            mov   rbp, rsp
            xor   rax, rax
            leave
            ret

quit:       mov   rax, -1
            ret