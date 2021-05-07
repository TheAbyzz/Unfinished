; A sequence of numbers is called bitonic if it consists of an increasing
; sequence followed by a decreasing sequence or if the sequence can
; be rotated until it consists of an increasing sequence followed by a
; decreasing sequence. Write an assembly program to read a sequence
; of integers into an array and print out whether the sequence is
; bitonic or not. The maximum number of elements in the array
; should be 100. You need to write 2 functions: one to read the
; numbers into the array and a second to determine whether the
; sequence is bitonic. Your bitonic test should not actually rotate the
; array.
;
; elements : -2 147 483 648 - 2 147 483 647 (double word)
; 242
; 64 <-- registers
; 107

section .data
	array: dw 5,10,2,5,3 

section .text
	global main

main:       push rbp
            mov  rbp, rsp
            lea  rdi, [array]
            call 

; we dont need to save rbp -> no local variables, no register to be saved, no need for backtracing

; bitonic_ck(index, size-2, size, nr_of_elevation_change)
bitonic_ch: cmp   rdi, rsi
            jz    quit
            mov   eax, [array+rdi]
            mov   ebx, [array+rdi+1]
            mov   ecx, [array+rdi+2]
            xor   r10, r10
            xor   r11, r11
            cmp   eax, ebx       if ebx bigger -> r11b = 1
            sets  r10b
            cmp   ebx, ecx
            sets  r11b           if ecx bigger -> r12b = 1       
            add   r10b, r11b
            xor   r12b, r12b
            cmp   r10b, 1        r11b = 1 -> peak or valley 
            setz  r12b
            add   rdx, r12b      if more than 2 peaks or valleys no_bitonic
            cmp   rdx, 3
            jz    quit           when end is reached we have to do a final check
            inc   rdi            where we check if a peak or valley is "hidden" outside
            call  bitonic_ck     the range 
            
quit:       xor   rax, rax
            cmp   rdi, rsi
            jnz   negative
            
            mov   eax, [array+rdi]        ; DONT USE RAX, ITS FOR RETURN VALUE
            mov   ebx, [array+rdi+1]
            cmp   eax, ebx
            sets  rax                       1 if rising at end/ 1 if falling at end

            mov   eax, [array]
            mov   ecx, [array+1]
            xor   r10, r10           
            cmp   eax, ebx
            sets  r10                       1 if rising at start/ 1 if falling at end

            add   rax, r10                  1 if peak or valley
            xor   r10, r10        
            cmp   rax, 1
            setz  r10b
            add   rdx, r10
            cmp   rdx, 3
            jz    negative

            xor   r10, r10
            cmp   ebx, eax
            sets  r10b

            add   rax, r10
            mov   bl, 3
            div   bl

            and   ah, ah






                      1 = rsising, 0 = falling (2 and 1) = 3   or  (0 and 0) = 0 safe
                                2 = both rising          (2 and 0) = 2   or  (0 and 1) = 1 not safe
                                  0 = both falling

            2 = both falling / 1 = end higher NO         2 = both falling / 0 = start higher YES

            0 = both rising / 1 = end higher YES          0 = both rising / 0 = start higher NO



negative:   leave
            ret