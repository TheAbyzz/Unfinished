; "64 Bit Intel Assembly Language Programming for Linux"

; p.112 exercise 4.

; Write a test program to evaluate how well the hashing function below works.

; int multipliers [] = {123456789, 234567891, 345678912, 456789123,
;                       567891234, 678912345, 789123456, 891234567};

; int hash (unsigned char *S) {
;     unsigned long h = 0;
;	  int i = 0;
;	  while (s[i]) {
;         h + s[i] * multipliers[i%8];
;         i++;
;     }
;     return h % 99991;
; }     
;
; Your test program should read a collection of strings using scan£
; with the format string "%79s" where you are reading into a charac­ter 
; array of 80 bytes. Your program should read until scan£ fails
; to return 1 . As it reads each string it should call hash ( written in
; assembly ) to get a number h from 0 to 99990. It should increment
; location h of an array of integers of size 9999 1 . After entering all
; the data, this array contains a count of how many words mapped
; to a particular location in the array. What we want to know is how
; many of these array entries have 0 entries, how many have 1 entry,
; how many have 2 entries, etc. When multiple words map to the
; same location, it is called a "collision" . So the next step is to go
; through the array collision counts and increment another array by
; the index there. There should be no more than 1000 collisions, so
; this could be done using
;
; for (i = 0; i < 99991; i++) {
;     k = collisions[i];
;     if (k > 999) k = 999;
;     count[k]++;
; }
;
; After the previous loop the count array has interesting data. Use a
; loop to step through this array and print the index and the value
; for all non-zero locations.

; An interesting file to test is "/usr /share/diet/words"

section .data
      fmt: db "%d %d",0x0a,0
	  multipliers: dd 123456789,234567891,345678912,456789123,567891234,678912345,789123456,891234567

section .text
	  global main
	  extern printf

; 80 bytes for char array + 199982 bytes (99991 x word) for hash table + 3999 bytes 
; (999 x double word) for collision data table, totalling 204061 bytes.

main: push  rbp
      mov   rbp, rsp
      sub   rsp, 204061

; zeroes the hash and collision data tables
      
      xor   ax, ax
      mov   rdi, rsp
      mov   rcx, 204061
      rep   stosb

; sets the last byte of the 80 byte char array to 10. The syscall returns the nr of 
; given characters + a newline character (10) if there's room for it. This makes 
; parsing the input easier. We only need to check for 10 in the Hash function.
; It appears we're not using the scan string instruction for scanning 10 since
; we already know the nr of given characters.

      mov   byte [rbp-1], 10

; takes the user input, calls the hash function and updates the hash table
      
.L1:  mov   rax, 0
      mov   rdi, 0
      lea   rsi, [rbp-80]
      mov   rdx, 79
      syscall
      cmp   rax, 1
      jz    .end
      lea   rdi, [rbp-80]
      call  hash      
      mov   di, [rbp-200062+rax*2]
      inc   di
      mov   [rbp-200062+rax*2], di

; prints the hash table
   
      xor   rbx, rbx
.L2:  movzx rdx, word [rbp-200062+rbx*2]
      cmp   dx, 0
      jz    .ze
      lea   rdi, [fmt]
      mov   esi, ebx
      xor   rax, rax
      call  printf

.ze:  inc   rbx
      cmp   rbx, 99991
      jnz   .L2
      jmp    .L1     

; updates the collision data table

.end: xor   rax, rax
      mov   bx, 999                               

.L3:  movzx rcx, word [rbp-200062+rax*2]
      cmp   cx, 999
      cmovg cx, bx
      mov   edx, [rbp-204061+rcx*4]
      inc   edx
      mov   [rbp-204061+rcx*4], edx
      inc   rax
      cmp   rax, 99991
      jnz   .L3

; prints the collision data table

      xor   rbx, rbx
.Lo:  mov   edx, [rbp-204061+rbx*4]                
      cmp   edx, 0
      jz    .ze2
      lea   rdi, [fmt]
      mov   rsi, rbx
      xor   rax, rax
      call  printf
.ze2: inc   rbx
      cmp   rbx, 999
      jnz   .Lo

      add   rsp, 204061
      xor   rax, rax
      leave
      ret

hash: mov   sil, 8                 
      xor   rbx, rbx
      xor   rcx, rcx

.L1:  movzx r8, byte [rdi+rbx]
      cmp   r8, 10
      jz    .end
      mov   rax, rbx
      div   sil
      shr   ax, 8
      and   rax, 0xff
      mov   eax, [multipliers+eax*4]
      imul  r8, rax
      add   rcx, r8
      inc   rbx
      jmp   .L1
      
.end: mov   rdx, 0xffffffff00000000
      and   rdx, rcx
      shr   rdx, 32
      mov   rax, 0xffffffff
      and   rax, rcx
      mov   rcx, 99991
      div   ecx
      mov   eax, edx
      ret
