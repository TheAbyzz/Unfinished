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
; case statement p.89

%define commands_size 4

section .data
    scanf_format: db "%21s"
    
    printf_format: db "%d ",0
    commands: dq "add","union","print","quit"
	switch: dq main.case0, main.case1, main.case2, main.case3, main.default

section .bss
	command_input: resq 1
    value1: resd 1
    value2: resd 1
    sets: resd 10000000
    set_sizes: resd 10

section .text
	global main
	extern scanf
	extern printf

main:       push   rbp
            mov    rbp, rsp
            call   read_input
            leave
            jmp    [switch+rax*8]

.case0:     mov    edi, [value1]
            cmp    rdi, 9
            jg     main
            mov    esi, [value2]
            cmp    rsi, 999999
            jg     main
            push   rbp
            mov    rbp, rsp
            call   add
            leave
            jmp    main

.case1:     mov    edi, [value1]
            cmp    rdi, 9
            jg     main
            mov    esi, [value2]
            cmp    rsi, 9
            jg     main
            push   rbp
            mov    rbp, rsp
            call   union
            leave
            jmp    main

.case2:     mov    rdi, [value1]
            cmp    rdi, 9
            jg     main
            push   rbp
            mov    rbp, rsp
            call   print
            leave
            jmp    main

.case3:     jmp    .end

.default:   jmp    main

.end:       xor    rax, rax
            ret

; read_input(void)
read_input: push   rbp
            mov    rbp, rsp
            lea    rdi, [scanf_format]
            lea    rsi, [command_input]
            lea    rdx, [value1]
            lea    rcx, [value2]
            xor    rax, rax
            call   scanf
            leave
            mov    rbx, [command_input]
            xor    rax, rax

.for:       cmp    rax, commands_size
            jz     .end_for
            mov    rcx, [commands+rax*8]
            cmp    rcx, rbx
            jz     .end_for
            inc    rax              
            jmp    .for

.end_for:   ret

; add(set_number, value)
add:        mov    eax, [set_sizes+rdi*4]
            cmp    rax, 1000000
            jz     .fault
            mov    rdx, rdi
            imul   rdx, 4000000
            xor    rbx, rbx

.for:       cmp    rbx, rax
            jz     .end_for
            mov    ecx, [sets+rdx+rbx*4]
            cmp    ecx, esi
            jl     .next
            jz     .end_for
            mov    ecx, [sets+rdx+rbx*4+4]
            mov    [sets+rdx+rbx*4+4], esi
            mov    esi, ecx
            
.next:      inc    rbx
            jmp    .for

            mov    eax, [set_sizes+rdi*4]
            inc    eax
            mov    [set_sizes+rdi*4], eax

.end_for:   xor    rax, rax  
            
.fault:     ret

; union(set1_number, set2_number)
union:      mov     eax, [set_sizes+rsi*4]      
            

            mov     rbx, rdi
            imul    rbx, 4000000
            xor     r8, r8
            
.for        cmp     r8, rax
            jz      .end_for
            mov     esi, [sets+rbx+r8*4]
            xor     rdx, rdx
            mov     ecx, [set_sizes+rdi*4]
            push    r8
            push    rax
            push    rbp
            mov     rbp, rsp
            call    bin_search
            pop     rax
            pop     r8
            leave
            inc     r8
            jmp     .for

.end_for:   xor     rax, rax

.fault:     ret 

; bin_search(set_number, search_value, start_index_of_subset, end_index_of_subset)
bin_search: mov     eax, edx
            sub     eax, ecx
            ror     eax, 1
            mov     ebx, [sets+rdi+rax*4]
            cmp     ebx, esi
            jz      .end
            cmp     rax, 0
            jz      .add
            cmovl   rcx, rax
            cmovg   rdx, rax
            push    rbp
            mov     rbp, rsp
            call    bin_search
            leave
            jmp     .end

.add:       push    rbp
            mov     rbp, rsp
            call    add 
            leave
            
.end:       ret

; print(void)
print:      xor     rdx, rdx
            mov     ebx, [set_sizes+rdi*4]
            mov     rcx, rdi
            lea     rdi, [printf_format]

.for:       cmp     rdx, rbx
            jz      .end_for
            push    rbp
            mov     rbp, rsp

            mov     r8, rcx
            imul    r8, 4000000
            add     r8, sets
            mov     r9, rdx
            imul    r9, 4
            add     r8, r9
            mov     esi, [r8]
            xor     rax, rax
            call    printf
            leave
            inc     rdx
            jmp     .for

.end_for:   xor     rax, rax
            ret