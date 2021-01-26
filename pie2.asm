; When I linked the program below with libc for the first time I ran into an interesting feature that 
; deserved some digging into. So without further ado, let's dig right into it!

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

; Unknowingly when I assembled and linked the program with following command:
;
; nasm -felf64 pie.asm && gcc pie.o -o pie_ex
;
; I received the following error message:
;
; /usr/bin/ld: bill calculator.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIC
; /usr/bin/ld: final link failed: Nonrepresentable section on output
; collect2: error: ld returned 1 exit status
;
; QUICK REVIEW OF RELOCATION
;
; Relocation is the act of fixing addresses and it's usally done by the linker but in some cases it can be done by the
; executable itself. Somehow the linker needs to know where in a object file/exectuable relocations are required. It's the
; assembler's task to inform the linker about any relocations and it's done by means of a relocation section, which is a
; part of the object file. The relocation sections contains relocation types, which describe what kind of relocation is
; required. If we examine the output below we see that 2 relocations are required to turn pie.o into an executable (pie_ex).
; We'll take a closer look at the columns in the relaction table in a moment but notice how the 32 bit addresses of lea and 
; printf call in pie.o that the relocation entries point at are both zeroed.
;
; readelf -r pie.o
;
;  ----------------------------------------------------------------------------------
; | Relocation section '.rela.text' at offset 0x340 contains 2 entries:              |
; |   Offset          Info           Type           Sym. Value    Sym. Name + Addend |
; | 000000000008  00020000000b R_X86_64_32S      0000000000000000 .data + 0          |
; | 000000000011  000500000009 R_X86_64_GOTPCREL 0000000000000000 printf - 4         |
;  ----------------------------------------------------------------------------------
;
; objdump -d -Mintel pie.o
; 
;  ----------------------------------------------------------------------------------
; | pie.o:     file format elf64-x86-64                                              |     
; |                                                                                  |
; |                                                                                  |
; | Disassembly of section .text:                                                    |
; |                                                                                  |
; | 0000000000000000 <main>:                                                         |
; |    0: 55                    push   rbp                                           |        
; |    1: 48 89 e5              mov    rbp,rsp                                       |
; |    4: 48 8d 3c 25 00 00 00  lea    rdi,ds:0x0                                    |
; |    b: 00                                                                         |
; |    c: 48 31 c0              xor    rax,rax                                       |
; |    f: ff 15 00 00 00 00     call   QWORD PTR [rip+0x0]        # 15 <main+0x15>   |
; |   15: 48 31 c0              xor    rax,rax                                       |
; |   18: c9                    leave                                                |
; |   19: c3                    ret                                                  |
;  -----------------------------------------------------------------------------------
;
; R_86_64_32S 
;
; This relocation type means take the value (00 00 00 00) at the offset (000000000008), add a symbolic value + addend to it (00060310),
; trunctate the result to 32 bits and finally check that result sign-extends to the original value/result? before storing the result back at the same offset.
; The sign-extension is checked to verify that the size of the program doesn't exceed the capability of 32 bit absolute addressing e.g. if the 
; size of the program exceeds 2 GiB some addresses of data or functions may lie too far from where they are referenced. (code model anf conanonical adr.)
;
; R_X86_64_GOTPCREL
;
; ...
;
; PROBLEM
;
; If the pie.o were to turned into an ordinary executable that was based on 32 bit absolute addressing and loaded under the 2 GiB limit at a known load
; address, the addresses in pie.o would be resolved according to the respective relocation entries. It's not though cause the linker I was using was
; configured with --enable-default-pie flag and due this expected an object file that could be linked into a position independent executable (pie). Pie 
; is based on relative addressing and can thus be loaded anywhere in the memory, above the 2 GiB limt if prefered. In short there's a conflict between
; the linkers assumption about the code and the actual code. The code I wrote doesn't support pie. The error message mentions something about -fPIC, where
; PIC stands for postion independent code. This is C/C++ compiler flag used for compiling the source code into a pic supporting object file. Pic appears to
; be used as generic term for exectuables which are based on relative addresses whereas pie is exlusivly used for executables that aren't libraries. The
; distinction is clearer in compiling C/C++ where -fPIE flag is used for non-libraries and -fPIC flag for libraries. I still don't know how to interpret 
; the "/usr/bin/ld: final link failed: Nonrepresentable section on output" in the error message.
;
; SOLUTION
;
; We've got 2 options 
;
; 1. Leave the code as it is and override the default behaviour of the linker to get a 32 bit absolute addressing based executable
;
;    gcc -no-pie pie.o -o pie_ex
;
;    If you now examine pie_ex you'll see that the addresses have been fixed
;
;    objdump -d -Mintel pie_ex
;  
;    --------------------------------------------------------------------------------
;   | 00000000004004f0 <main>:                                                       |
;   |   4004f0: 55                    push   rbp                                     |
;   |   4004f1: 48 89 e5              mov    rbp,rsp                                 |
;   |   4004f4: 48 8d 3c 25 30 10 60  lea    rdi,ds:0x601030                         |
;   |   4004fb: 00                                                                   |
;   |   4004fc: 48 31 c0              xor    rax,rax                                 |
;   |   4004ff: e8 ec fe ff ff        call   4003f0 <printf@plt>                     |
;   |   400504: 48 31 c0              xor    rax,rax                                 |
;   |   400507: c9                    leave                                          |
;   |   400508: c3                    ret                                            |
;   |   400509: 0f 1f 80 00 00 00 00  nop    DWORD PTR [rax+0x0]                     |
;    --------------------------------------------------------------------------------
; 
;
; 2. Make the necessary changes in pie.asm to get a tasty pie
;
;    To solve the earlier error, we should do the following fix in pie.asm:
;    
;        32 bit relative addressing
;      
;            lea rdi, [msg] --> lea rdi, [rel msg]
;                         
;            The rel keyword in the instruction can be lef out if we add the "default rel"
;            directive somewhere in pie.asm, not inside the sections though
;
;            ...
;
;    There's another way to silent the error message
;
;        64 bit absolute addressing
;
;            lea rdi, [msg] -> mov rdi, qword msg 
;
;            ...
;          
;    Now if we try to compile & link pie.asm with: nasm -felf64 pie.asm && gcc pie.o -o pie_ex
;    
;    We get the error:
;
;    ./a.out: Symbol `printf' causes overflow in R_X86_64_PC32 relocation
;    Segmentation fault (core dumped)
;
;    To solve this error it turns out we have to do one the following fixes
;
;        32 bit relative addressing 
;
;            call printf --> call [rel printf WRT ..got] (rel can be omitted if we added default rel)
;
;            call printf --> call printf WRT ..plt
;
;            ... 
;    
;    Here's complete version:
;

section .data
    msg: db "Hello world!",0x0a,0        
 
section .text
    global main
    extern printf
 
main: push rbp
        mov  rbp, rsp
        lea  rdi, [rel msg]
        xor  rax, rax
        call [rel printf WRT ..got]
 
        xor  rax, rax
        leave
        ret

     Now if we examie pie_ex

     objdump -d -Mintel pie_ex

     ...

; QUICK HISTORY OF PIE/PIC  
;
; What happened as far as I understand was that the linker, which is configured with --enable-default-pie flag noticed that the code
; wasen't written/assembled for position independent executable aka pie and therefore refused to proceed. Pie uses relative
; addressing, which makes placing the pie anywhere in the virtual memory possible but more on this later. The program above uses
; () absolute adressing and thus cannot be placed anywhere in the virtual memory and certainly not above the () bound. Let's go back
; in time to see where it all started. Before memory management unit (mmu) and virtual addresses where invented the addressing of
; programs were based on real physical addresses and to allow multiple programs to be loaded on memory and perhaps even run simultaneously, 
; they couldn't used addressing that was based on fixed addresses, instead they used something called relative addressing and programs
; where this was utilized were called position independent executables (pie). I'm not going to go into great detail on how relative addressing was 
; implemented back then but the principle is that the addresses of data segments that are initialized prior to program execution are calculated
; using offsets and some base address. Once mmu and virtual addresses were invented there was no real use for pie anymore or was there? I'm not 
; sure. Pie or position independent code (pic) as it was this time called made it back to the surface in the form of a shared/dynamic library.
; A shared or dynamic library is a library that's not statically linked and one that can be shared by multiple programs simultaneously hence the
; name. Another technique used for shared/dynamic libraries called load-time relocation emerged around the same time. Let's cover load-time
; relocation first and briefly. When a program calls for a function in shared/dynamic library that library if not already present gets first 
; loaded into the process space of the program and then linked. The downside of this approach is that every program needs their own copy of that 
; library, which makes ram usage less efficient and every single program has to go through process of loading and linking before the function
; could finally be called and that slowed down things a bit. Pie solved both of these problems by allowing one single copy of the library to be
; shared by multiple programs. Shared/dynamic libraries implemented as pie were not loaded into the process space of an already existing program.
; Please note that both of these techniques emerged before x86_64 and that load-time relocation might not even work on x86_64. Maybe the advantages
; of the pie enetually lead to the neglection of load-time relocation, who knows? The earlier platforms were not designed with pic in mind and
; therefore it wasen't as efficiently implimented as it now on x86_64. As we move to 64 bit systems things change a bit. Now we have 2 types of
; shared/dynamic libraries; dynamically loaded libraries and dynamically linked libraries. Dynamically loaded libraries if not already present are
; loaded and linked by the program via requests. The program has full control over the usage of the library and this approach is commonly used in
; plugin programing. Dynamically linked libraries if not already present are loaded and linked by the OS as the program launches. Later (32 bit) it became
; common practise to make the executables themseleves (non libraries) pie allowing for something called address space layout randomization (aslr),
; which makes exploiting vulnerabilities harder. Pic name appears to be used as a generic name for code where the particular technique is used
; whereas pie is exlusivly used for executables (non libraries).




















https://www.cs.swarthmore.edu/~kwebb/cs31/s15/bucs/virtual_memory_is.html
https://www.bottomupcs.com/virtual_memory_is.xhtml
http://reader.epubee.com/books/mobile/ee/ee571bde060c36770e1b10573760804f/text00107.html
https://stackoverflow.com/questions/6093547/what-do-r-x86-64-32s-and-r-x86-64-64-relocation-mean
https://stackoverflow.com/questions/2463150/what-is-the-fpie-option-for-position-independent-executables-in-gcc-and-ld/51308031#51308031
https://www.quora.com/What-is-PC-relative-addressing

https://stackoverflow.com/questions/10486116/what-does-this-gcc-error-relocation-truncated-to-fit-mean
https://www.technovelty.org/c/relocation-truncated-to-fit-wtf.html
https://stackoverflow.com/questions/33318342/when-is-it-better-for-an-assembler-to-use-sign-extended-relocation-like-r-x86-64

which basically means "the value of the symbol pointed to by this relocation, plus any addend", in both cases. For R_X86_64_32S the linker then verifies that the generated value sign-extends to the original 64-bit value.
https://stackoverflow.com/questions/6093547/what-do-r-x86-64-32s-and-r-x86-64-64-relocation-mean


; We have 2 options to get the program above work
;
; 1. We could assemble and link the program above as non position independent executable
;
;    nasm -felf64 pie.asm && gcc -no-pie pie.o
;
; 2. We could make the necessary changes in the program above and assemble and link it as pie without -no-pie flag

  section .data
       msg: db "Hello world!",0x0a,0        
 
  section .text
       global main
       extern printf
 
  ; The "rel" keyword can be omitted if "default rel" is added here
 
  main: push rbp
        mov  rbp, rsp
        lea  rdi, [rel msg] ; or mov rdi, qword msg (64 bit absolute addressing)
        xor  rax, rax
        call [rel printf WRT ..got] ; or call printf WRT ..plt
 
        xor  rax, rax
        leave
        ret

; The missing "rel" keyword in "lea rdi, [msg]" caused the earlier error meassage
;
; /usr/bin/ld: bill calculator.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIC
; /usr/bin/ld: final link failed: Nonrepresentable section on output
; collect2: error: ld returned 1 exit status
;
; If we don't call printf as we do in the fixed version we'll get
;
; ./a.out: Symbol `printf' causes overflow in R_X86_64_PC32 relocation
; Segmentation fault (core dumped)

; -------------------------------------------------------------------------------------------------------------------------------------------

; 64-bit code on OS X can't use 32-bit absolute addressing at all. Executables are loaded at a base address above 4GiB, so label addresses 
; just plain don't fit in 32-bit integers, with zero- or sign-extension. RIP-relative addressing is the best / most efficient solution, 
; whether you need it to be position-independent or not1.
https://stackoverflow.com/questions/47300844/mach-o-64-bit-format-does-not-support-32-bit-absolute-addresses-nasm-accessing

; 32-bit absolute relocation aren't allowed in an ELF shared object; that would stop them from being loaded outside the low 2GiB 
; (for sign-extended 32-bit addresses). 64-bit absolute addresses are allowed, but generally you only want that for jump tables or other static 
; data, not as part of instructions.1
https://stackoverflow.com/questions/43367427/32-bit-absolute-addresses-no-longer-allowed-in-x86-64-linux/46493456

; x86 code models
https://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models

; relocations explained
https://www.intezer.com/blog/elf/executable-and-linkable-format-101-part-3-relocations/

; relative 32 bit jump is more efficient thant 64 absolute jump
https://stackoverflow.com/questions/26955200/why-does-jmpq-of-x86-64-only-need-32-bit-length-address

; with and without -fpic
https://unix.stackexchange.com/questions/116327/loading-of-shared-libraries-and-ram-usage

; plt and got
https://www.technovelty.org/linux/plt-and-got-the-key-to-code-sharing-and-dynamic-libraries.html

; The R_X86_64_32 and R_X86_64_32S relocations truncate the computed value to 32-bits. The linker must verify that the generated value for the 
; R_X86_64_32 (R_X86_64_32S) relocation zero-extends (sign-extends) to the original 64-bit value. 

; Most programs are compiled in a way that they use shared libraries. Those libraries are not part of the program image (even though it is 
; possible to include them via static linking) and therefore have to be referenced (included) dynamically. As a result, we see the libraries 
; (libc, ld, etc.) being loaded in the memory layout of a process. Roughly speaking, the shared libraries are loaded somewhere in the memory 
; (outside of process’ control) and our program just creates virtual “links” to that memory region. This way we save memory without the need 
; to load the same library in every instance of a program.

; How does the shared library access externally the data from the calling process?
