; When I tried to assemble and link the program below with the following command: nasm -felf64 pie.asm && gcc pie.o

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

; I received the following error message:
;
; /usr/bin/ld: bill calculator.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIC
; /usr/bin/ld: final link failed: Nonrepresentable section on output
; collect2: error: ld returned 1 exit status
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
; common practise to make the executables themseleves (non libraries) pie to allow for something called address space layout randomization (aslr),
; which makes exploiting vulnerabilities harder. Pic name appears to be used as a generic name for code where the particular technique is used
; whereas pie is exlusivly used for executables (non libraries).

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
        lea  rdi, [rel msg]
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