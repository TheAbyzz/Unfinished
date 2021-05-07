section .data
	array: db 1,2,5,4,3,2

section .text
	global main

main:     push rbp
          mov  rbp, rsp
          call ck_bitnc

          xor  rax, rax
          leave
          ret

// ck_bitnc(start_address, length, )
ck_bitnc: push rbp
          mov  rbp, rsp


// up-down
// down-up
// up-down-up     first element < last element
// down-up-down   first element < last element
