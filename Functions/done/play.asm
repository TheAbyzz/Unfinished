section .data
    msg: db "Hello world!",0x0a,0        
 
section .text
    global main
    extern printf
 
main: push rbp
      mov  rbp, rsp
      lea  rdi, [msg]
      xor  rax, rax
      call printf
 
      xor  rax, rax
      leave
      ret

; https://daftsex.com/watch/-190573291_456240244