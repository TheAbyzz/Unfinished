; "64 Bit Intel Assembly Language Programming for Linux"
;
; p.97 exercise 2.
;
; Write an assembly program to generate an array of random integers
; ( by calling the C library function random) , to sort the array using
; a bubble sort function and to print the array. The array should be
; stored in the bss segment and does not need to be dynamically
; allocated. The number of elements to fill, sort and print should
; be stored in a memory location. Write a function to loop through
; the array elements filling the array with random integers. Write a
; function to print the array contents. If the array size is less than or
; equal to 20, call your print function before and after printing.
;
; I wrote a c program which printed RAND_MAX and it turned out to be
; 2147483647 which fits in a 4 byte register. System time could be use
; as a "seed" to generate a different sequence of numbers on each run.
; The output is unfortunately the same each time.

%define array_size 15

section .data
      printf_doubleword: db "%d ",0
      printf_newline: db 0x0a

section .bss
	array: resd array_size

section .text
	global main
      extern printf
	extern rand

main:        push rbp
             mov  rbp, rsp
             call rand_fill
             leave

             mov  rax, array_size
             cmp  rax, 20
             jg   skip
             push rbp
             mov  rbp, rsp
             call print
             leave

skip:        push rbp
             mov  rbp, rsp
             call bubble_sort
             leave

             mov  rax, array_size
             cmp  rax, 20
             jg   skip2
             push rbp
             mov  rbp, rsp
             call print
             leave

skip2        ret

rand_fill:   xor  rbx, rbx

for1:        cmp  rbx, array_size
             jz   end_for1
             xor  rax, rax
             call rand
             mov  [array+rbx*4], eax
             inc  rbx
             jmp  for1

end_for1:    xor  rax, rax
             ret

bubble_sort: mov  rax, array_size
             dec  rax
             xor  rbx, rbx
             xor  rcx, rcx

for2:        cmp  rbx, rax
             jz   end_for2
             mov  edx, [array+rbx*4]
             mov  esi, [array+rbx*4+4]
             cmp  edx, esi
             jle  in_order
             mov  [array+rbx*4], esi
             mov  [array+rbx*4+4], edx
             mov  rcx, 1

in_order:    inc  rbx
             jmp  for2


end_for2:    cmp  rcx, 1
             jz   bubble_sort
             xor  rax, rax
             ret

print:       xor  rbx, rbx

for3:        cmp  rbx, array_size
             jz   end_for3
             push rbp
             mov  rbp, rsp
             lea  rdi, [printf_doubleword]
             mov  esi, [array+rbx*4]
             xor  rax, rax
             call printf
             leave
             inc  rbx
             jmp  for3

end_for3:    push rbp
             mov  rbp, rsp
             lea  rdi, [printf_newline]
             xor  rsi, rsi
             xor  rax, rax
             call printf
             leave
             xor rax, rax
             ret
