; "64 Bit Intel Assembly Language Programming for Linux"
;
; p.98 exercise 6.
;
; Write an assembly program to read two 8 byte integers with scanf
; and compute their greatest common divisor using Euclid's algo­rithm, 
; which is based on the recursive definition
;
;              
; gcd(a,b,"c") = { a              if b = 0   
;            { gcd(b,a mod b,"c") otherwise
;
; The c parameter is not relevant, I added it only to make backtracing a bit more interesting. It's incremented
; every time gcd is called, saved on the stack in the stack frame and passed to the callee (gcd). After the caller's 
; base pointer is saved and a new baser pointer is created, local variables, registers and parameters are saved the stack 
; before the next function is called. In Linux the registers: rdi , rsi, rdx, rex, r8 and r9 are used for parameter 
; passing but additional parameters and parameters which do not fit in the registers are saved on the stack. Parameters 
; are accessed by positive offsets of rbp and local variables by negative offsets of rbp. Parameters and local variables 
; are sometimes accessed by offsets rsp. Remember the 16 byte stack aligmnent requirement!  

section .data
	scanf_format: db "%ld %ld",0
	printf_format: db "%ld",0x0a,0

section .text
	global main
	extern scanf
	extern printf

main:   push  rbp                       ; saves the caller's stack frame and creates a new one for the current function
        mov   rbp, rsp
        sub   rsp, 32                   ; makes room on stack for local variables (quadwords); a, b and c and subtracts 
        lea   rdi, [scanf_format]       ; 8 additional bytes to fullfill the 16 byte stack alignment requirement
        lea   rsi, [rbp-8]
        lea   rdx, [rbp-16]
        xor   rax, rax
        mov   [rbp-8], rax              ; initalizes the local variables to zero
        mov   [rbp-16], rax
        mov   [rbp-24], rax
        call  scanf                     ; scanf returns the nr of successfully captured values in rax

        mov   rdi, [rbp-8]              
        mov   rsi, [rbp-16]
        mov   rdx, [rbp-24]
        call  gcd                       ; gcd returns the greatest common divisor in rax

        lea   rdi, [printf_format]      
        mov   rsi, rax
        xor   rax, rax
        call  printf                    ; prints the the greatest common divisor

        add   rsp, 32                   ; cleans the stack
        leave                           ; restores caller's stack frame
        ret

gcd:    push  rbp                       
        mov   rbp, rsp
        mov   rbx, rdx                  ; 
        inc   rbx                       ; increments c
        push  rbx                       ; saves rbx which holds the parameter c

        cmp   rsi, 0                    ; checks if b = 0
        cmovz rax, rdi
        jz    else                         

        mov   rdx, 0xffffffff00000000   ; performs the operation: a mod b
        and   rdx, rdi
        mov   rax, 0xffffffff
        and   rax, rdi
        div   rsi
        mov   rdi, rsi
        mov   rsi, rdx
                      
        mov   rdx, rbx
        sub   rsp, 8                    
        call  gcd
        add   rsp, 8                                              

else:   pop   rbx
        leave                          
        ret   
