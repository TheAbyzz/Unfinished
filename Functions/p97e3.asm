; A Pythagorean triple is a set of three integers a , b and c such
; that a^2 + b^2 = c^2. Write an assembly program to print all the
; Pythagorean triples where c <= 500. Use a function to test whether
; a number is a Pythagorean triple.

section .text
	global main

main:      push rbp
           mov  rbp, rsp
           sub  rsp, 16

           xor  rcx, rcx

.for:      cmp  rcx, 500
           jg   .end_for
           lea  rdi, [rbp-8]
           lea  rsi, [rbp-16]
           mov  rdx, rcx
           call pyth_trip
           cmp  rax, 1
           jnz  .neg
           lea  rdi, [printf_fmt]
           mov  rsi, [rbp-8]
           mov  rdx, [rbp-16]
           call printf

.neg:      inc  rbx
           jmp  .for

.end_for:  add  rsp, 16
           xor  rax, rax
           leave
           ret

pyth_trip: push rbp
           mov  rbp, rsp

           mov  rbx, rdx
           imul rbx, rbx
           xor  rcx, rcx

for1:      cmp  rcx, rdx
           jz   end_for1





1 2 3 4  5  6  7


0 1 4 9 16 25 36 49 64 81 100

36 + 49 = 85
81 + 4  = 85   several options

+1 +3 +5 +7 +9 +11

a1 = 1                           3rd = 9
q = 4

1 * (1 - 4^3)  1 * (-11)    11
------------ = --------- = ----
1-4               -3         3

2^2 + 4^2 = 4 + 16 = 20

3^2 + 4^2 = 9 + 16 = 25