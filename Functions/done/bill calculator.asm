; "64 Bit Intel Assembly Language Programming for Linux"
;
; p.97 exercise 1.
;
; Write an assembly program to produce a billing report for an electric
; company. It should read a series of customer records using scanf
; and print one output line per customer giving the customer details
; and the amount of the bill. The customer data will consist of a name
; (up to 64 characters not including the terminal 0) and a number
; of kilowatt hours per customer. The number of kilowatt hours is
; an integer. The cost for a customer will be $20.00 if the number of
; kilowatt hours is less than or equal to 1000 or $20.00 plus 1 cent
; per kilowatt hour over 1000 if the usage is greater than 1000. Use
; quotient and remainder after dividing by 100 to print the amounts
; as normal dollars and cents. Write and use a function to compute
; the bill amount (in pennies)

; C library functions which use SSE or AVX instructions (used for parallel calculations) require 
; the stack pointer to be aligned to 16 byte boundary in memory because this allows the local 
; variables to be placed at 16 byte alignments for SSE and AVX instructions. Same goes for the 
; data section, data has to be placed at 16 byte alignments for SSE and AVX instructions (applies only
; to packed (array) floats and doubles. 
; The 16 byte requirement is related to performance and it might also allow for simpler physical 
; implementations. The memory is usually accessed in blocks (multiple of byte) and the block size
; depends on the system. If the variable size is smaller than the block size the variable is placed 
; at an address equal to a multiple of the variable size and if the block size is smaller than the 
; variable size the variable is placed at an address equal to a multiple of the block size. How
; missaligned data is handled depends on the system. Some systems recognises it and performs extra
; steps (additional memory accesses and shifting) which takes longer, some systems recognises it
; but cannot handle it, instead they throw an exception. If the stack is not aligned to a 16 byte
; boundary for C library functions which use SEE or AVX instructions a segmentation fault is issued.
; Some systems cannot handle missaligned data and crash if an attempt to access is made. Instructions
; may handle missaligned data differently. 
; Then there is this: "You can push and pop smaller values than  8 bytes, at some peril. It works as long 
; as the stack remains bounded appropriately for the current operation. So if you push a word and then push 
; a quad-word, the quad­ word push may fail. It is simpler to push and pop only 8 byte quantities" which is 
; taken from the book (64 Bit Intel Assembly Language Programming for Linux). I don't understand the second
; last sentence.
;
; Here we use lea "load effective address" to obtain the desired address. The instructions requires a
; base address and an optional offset e.g. lea rax, [lable+rbx*5+100]. It accepts 1,2,3,4,5,8 and 9 as
; constant multiplier.
;
; The return value from scanf is stored in rax and it tells how many of the inputs specified
; in the scanf format were successfully picked from stdin stream. If only 2 inputs are acceptable
; 3 inputs has to be specified in the scanf format because if only 2 inputs were specified in
; scanf format and 3 inputs were given scanf would return 2. Ascii numbers could be used
; to verify the character array input.

; Here scanf doesn't accept space characters continious string witout spaces (no spaces before)

; if an attempt to store a too large value in 64 bit register is made using scanf the value is trunctated
; cutted to max signed value, whereas on smalller registers it starts from the smallest negative

; https://stackoverflow.com/questions/19794268/scanf-reading-enter-key 

%define nr_of_samples 3

section .data
    printf_format: db "%s: %hd dollars %hd cents",0x0a,0
    scanf_format: db "%64s %hd",0
    name_array: times 64 db 0    

section .bss
    kWh_array: resw nr_of_samples
    dollars: resw 1
    pennies: resw 1

section .text
    global main
    extern scanf
    extern printf

main:           xor    rbx, rbx

for1:           cmp    rbx, nr_of_samples
                jz     end_for1
                push   rbp
                mov    rbp, rsp
                lea    rdi, [scanf_format]
                lea    rsi, [name_array+rbx*8]
                lea    rdx, [kWh_array+rbx*2]
                xor    rax, rax
                call   scanf
                leave
                inc    rbx
                jmp    for1

end_for1:       xor    rbx, rbx

for2:           cmp    rbx, nr_of_samples
                jz     end_for2
                push   rbp
                mov    rbp, rsp
                movzx  rdi, word [kWh_array+rbx*2]
                call   kWh_to_pennies
                leave
                mov    rcx, 100
                div    cx  
                mov    [dollars], ax
                mov    [pennies], dx
                push   rbp
                mov    rbp, rsp
                lea    rdi, [printf_format]
                lea    rsi, [name_array+rbx*8]
                movsx  rdx, word [dollars]
                movsx  rcx, word [pennies]
                xor    rax, rax
                call   printf
                leave
                inc    rbx
                jmp    for2

end_for2:       xor    rax, rax
                ret

kWh_to_pennies: mov    rax, rdi
                xor    rdi, rdi
                sub    rax, 1000
                cmovle rax, rdi
                add    rax, 2000
                mov    rdx, 0xffff0000
                and    rdx, rax
                shr    rdx, 16
                and    rax, 0xffff
                ret         
