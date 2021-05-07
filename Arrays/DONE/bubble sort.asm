section .text
	global bubble_sort

bubble_sort: push rbp
             push rbx
             push r12
             push r13
             push r14
             push r15

             dec  rsi

.while       xor  rax, rax
             xor  rbx, rbx

.for:        cmp rax, rsi
             jz  .end
             mov ecx, [rdi+rax*4]
             mov edx, [rdi+rax*4+4]
             cmp ecx, edx
             jle .in_order
             cmp edx, ecx
             jg  .in_order
             mov [rdi+rax*4], edx
             mov [rdi+rax*4+4], ecx
             mov rbx, 1

.in_order:   inc rax
             jmp .for

.end:        cmp rbx, 1
             jz  .while
             pop r15
             pop r14
             pop r13
             pop r12
             pop rbx
             pop rbp
             xor rax, rax
             ret