; "64 Bit Intel Assembly Language Programming for Linux"
;
; p.98 exercise 7.
;
; Write an assembly program to read a string of left and right paren­
; theses and determine whether the string contains a balanced set of
; parentheses. You can read the string with scanf using "%79s" into
; a character array of length 80. A set of parentheses is balanced if
; it is the empty string or if it consists of a left parenthesis followed
; by a sequence of balanced sets and a right parenthesis. Here's an
; example of a balanced set of parentheses: " ((()())())".
;
; A non zero return value indicates an unbalanced set of paranthesis.
; After running the program, echo $? command displays the return value.

section .data
	scanf_format: db "%79s",0

section .bss
	array: resb 80
	arraylen: 80

section .text
	global main
	extern scanf

main:         push rbp
              mov  rbp, rsp
              lea  rdi, [scanf_format]
              lea  rsi, [array]
              xor  rax, rax
              call scanf
              leave

              push rbp
              mov  rbp, rsp
              call para_balance
              leave

              ret 

para_balance: xor rax, rax
              xor rbx, rbx
              xor rdx, rdx

for:          cmp  rbx, arraylen
              jz   end_for
              mov  cl, [array+rbx]
              cmp  cl, 40
              setz dl
              add  rax, rdx
              cmp  cl, 41
              setz dl
              sub  rax, rdx
              xor  rdx, rdx
              inc  rbx
              jmp  for

end_for:      ret      