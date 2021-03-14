; POSITION INDEPENDENT CODE
;
; In this tutorial we'll be taking a look at position independent code also known as pic, an interesting
; feature, which is present in nearly all of the todays programs programs with programs running on
; embedded systems as an exception. I originally ran into this this feature while trying to 
; assemble example.asm below the way I'd been taught. I thought this particular feature deserved some 
; attention so I decied to write a tutorial about it. So without further ado, let's dig right into it!

; example.asm

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

; I went straight to ahead using the following command and was shortly faced with an error message
;
; nasm -felf64 example.asm && gcc example.o -o example (we got this error message mostly likely with gcc-9.2.0 or gcc-9.1.0 (unlikely))
;  ----------------------------------------------------------------------------------------------------------------------------------------
; | /usr/bin/ld: bill calculator.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIC |
; | /usr/bin/ld: final link failed: Nonrepresentable section on output                                                                     |
; | collect2: error: ld returned 1 exit status                                                                                             |
;  ----------------------------------------------------------------------------------------------------------------------------------------
;
; (update: The error message has changed a bit and looks like this on gcc-7.5.0 - 9.3.0)
;
;  ----------------------------------------------------------------------------------------------------------------------------------------
; | /usr/bin/ld: example.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIE         |
; | collect2: error: ld returned 1 exit status                                                                                             |
;  ----------------------------------------------------------------------------------------------------------------------------------------
; 
; The earlier error message mentions something about relocation so let's start from that.
;
; QUICK REVIEW OF RELOCATION
;
; Relocation in this context is an address issue that rises from the fact that the compiler doesn't consern
; itself with questions regarding the distribution of the source code (is all code collected into one file 
; or is it split into several files?), the use of libraries, the initialization code that prepares the 
; environment the code holds assumptions about, the deinitialization code that does the final cleanup and
; the virtual load address the executable is loaded to. These are all matters that eventually affect the 
; the virtual addresses and they are addressed by the linker. The compiler is mainly consered about the 
; matter of converting the code to machine code. Somehow the linker needs to be informed about these 
; relocations and it's done with help of a relocation table, which is injected into the object file. 
; This relocation table is generated by the assembler and it looks like this.
;
; readelf -r example.o
;  ----------------------------------------------------------------------------------
; | Relocation section '.rela.text' at offset 0x340 contains 2 entries:              |
; |   Offset          Info           Type           Sym. Value    Sym. Name + Addend |
; | 000000000008  00020000000b R_X86_64_32S      0000000000000000 .data + 0          |   
; | 000000000011  000500000009 R_X86_64_GOTPCREL 0000000000000000 printf - 4         |  
;  ----------------------------------------------------------------------------------
;
; Offset refers to the location where the address lies. Info in turn contains the index of symbol
; in the symbol table and architecture-dependent details, used for calculating the address. Type 
; describes the type of the symbol?. Sym. Value is equal to Sym. Name + Append and represent the
; current false address? Sym. Name + Addend is for printing purposes.
;
; R_X86_64_32S
;
; This relocation type means take the value (00 00 00 00) at the offset (000000000008), add the Sym. Value
; to it, trunctate the result to a 32 bit value and finally check that that resulting value sign-extends to
; the original value (00 00 00 00 or the result?). The sign-extension is perhaps checked to verified that the
; program doesn't exceed the capability of 32 bit absoluted addressing. If the size of the code exceeds 2 GiB
; some addresses of data or functions may lie too far from where they are referenced (code model?). Memory model     (IS LEA INSTRUCTION RELATIVE OR ABSOLUTE???)
; and conanonical addresses?
;
; R_X86_64_GOTPCREL
;
; The calculation done by the R_X86_64_GOTPCREL relocation gives the difference between the location in the GOT 
; where the symbol's address is given and the location where the relocation is applied. The address of prinft
; in the got table is patched into main where printf is called. If we look at the disassembled example.o below 
; we see that the byte at offset f of main consists of ff. This is the opcode for the 32 bit relative jump, 
; which is used in the small code model (default), in code that's under 2 Gib in size.
;
; The extended symbol table of example.o
;
; nm --debug-syms example.o
;  ----------------------------------------------------------------------------------
; | 0000000000000000 d .data                                                         |
; | 0000000000000000 a example.asm                                                   |
; | 0000000000000000 T main                                                          |
; | 0000000000000000 d msg                                                           |
; |                  U printf                                                        |
; | 0000000000000000 t .text                                                         |
;  ----------------------------------------------------------------------------------
;
; D/d = The symbol is in the initialized data section. 
; U = The symbol is undefined. 
;
; Now if we turn over to the disassembled example.o for a moment, we see that both addresses specified in the
; relocation table are set to zero (00 00 00 00).
;
; objdump -d -Mintel example.o
; 
;  ----------------------------------------------------------------------------------
; |  example.o:     file format elf64-x86-64                                         |     
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
;  ----------------------------------------------------------------------------------
;
; At first I was tempted to write a c++ program that could solve the relocations, but then I realised it would not have been able
; to solve all of them since the the dynamic linker plays a part. Anyways as I was writing the c++ code I got a picture of how the
; static linker works and I'll try to explain it here briefly.
;
; The gcc linker uses the ld linker for linking. The ld linker in turn uses a linker script for assembling the executable. The command
; "ld --verbose" will print the linker script. If we review the linker script we'll see the search directories which ld linkers go through
; as it searches for the sections, which are required for the creating the executable. As we continue reading the linker script we'll see 
; the load address, which in this case is 0x400000. After that comes the we'll see the sections in the order they are going to appear in the 
; executable. The input sections are mapped to output sections. The output sections are grouped into segments, some of which are loaded to
; memory (ram) as the program is launched. Padding is used to align some of the content to increase effiency.
;
; ELF "Executabl Linking Format" structure
;
;  --------------------------
; | ELF HEADER
; |-----------
; | PROGRAM 
; |
; |
; |
; 
;
;  ---------------------------------------------------------------------------------------------------------------------------------------
; |                                                                                                                                       |
; | ...                                                                                                                                   |
; |                                                                                                                                       |
; | /* Read-only sections, merged into text segment: */                                                                                   |
; | PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x400000)); . = SEGMENT_START("text-segment", 0x400000) + SIZEOF_HEADERS; |
; |                                                                                                                                       |                                      
; | ...                                                                                                                                   |
; |                                                                                                                                       |
;  ---------------------------------------------------------------------------------------------------------------------------------------
; https://reverseengineering.stackexchange.com/questions/16841/address-to-file-offset
; https://stackoverflow.com/questions/2187484/why-is-the-elf-execution-entry-point-virtual-address-of-the-form-0x80xxxxx-and-n
; https://stackoverflow.com/questions/38549972/why-elf-executables-have-a-fixed-load-address
; https://stackoverflow.com/questions/1685483/how-can-i-examine-contents-of-a-data-section-of-an-elf-file-on-linux
; https://stackoverflow.com/questions/18296276/base-address-of-elf
; https://stackoverflow.com/questions/16847741/processing-elf-relocations-understanding-the-relocs-symbols-section-data-an

; https://stackoverflow.com/questions/46123505/assembling-with-gcc-causes-weird-relocation-error-with-regards-to-data

; ROOT OF THE PROBLEM
;
; If the pie.o were to turned into an ordinary executable that was based on 32 bit absolute addressing and loaded under the 2 GiB limit at a known load
; address, the addresses in pie.o would be resolved according to the respective relocation entries. It's not though cause the linker I was using was
; configured with --enable-default-pie flag and due this expected an object file that could be linked into a position independent executable (pie). Pie 
; is based on relative addressing and can thus be loaded anywhere in the memory, above the 2 GiB limt if prefered. In short there's a conflict between
; the linkers assumption about the code and the actual code. The code I wrote doesn't support pie. The error message mentions something about -fPIC, where
; PIC stands for postion independent code. This is C/C++ compiler flag used for compiling the source code into a pic supporting object file. Pic appears to
; be used as generic term for exectuables which are based on relative addresses whereas pie is exlusivly used for executables that aren't libraries. The
; distinction is clearer in compiling C/C++ where -fPIE flag is used for non-libraries and -fPIC flag for libraries. I still don't know how to interpret 
: the "/usr/bin/ld: final link failed: Nonrepresentable section on output" in the error message.
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
;   |   4004ff: e8 ec fe ff ff        call   4003f0 <printf@plt>                     | (THIS LOOKS WEIRD TOO!!! WE SHOULD GET CALLQ WITH NON-PIE FLAG)
;   |   400504: 48 31 c0              xor    rax,rax                                 | (CHECK THE OUTPUT OF OBJDUMP AND SEE IF ITS AN ASSEMBLER/LINKER MATTER)
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
;    There's another workaround
;
;        64 bit absolute addressing
;
;            lea rdi, [msg] -> mov rdi, qword msg 
;
;            ...
;          
;    Now if we give it a try
;
;    nasm -felf64 pie.asm && gcc pie.o -o pie_ex
;    
;    We get the following error (we got this error message mostly likely with gcc-9.2.0 or gcc-9.1.0(unlikely))
;     ------------- ---------------------------------------------------------
;    | ./a.out: Symbol `printf' causes overflow in R_X86_64_PC32 relocation |  
;    | Segmentation fault (core dumped)                                     |
;     ----------------------------------------------------------------------
;
;    (update: The error message has changed a bit and looks like this on gcc-7.5.0 - 9.3.0)
;     ------------------------------------------------------------------------------------------------------------------------------------------------------
;    | /usr/bin/ld: example.o: relocation R_X86_64_PC32 against symbol `printf@@GLIBC_2.2.5' can not be used when making a PIE object; recompile with -fPIE |
;    | /usr/bin/ld: final link failed: bad value                                                                                                            |
;    | collect2: error: ld returned 1 exit status                                                                                                           |
;     ------------------------------------------------------------------------------------------------------------------------------------------------------
;
;
;    https://linuxconfig.org/how-to-switch-between-multiple-gcc-and-g-compiler-versions-on-ubuntu-20-04-lts-focal-fossa
     https://www.cyberciti.biz/faq/linux-how-to-check-what-compiler-is-running-installed/

     gcc 9.3 march 12, 2020
     gcc 8.4 march 4 , 2020
     gcc 7.5 November 14, 2019
     gcc 9.2 November 12, 2019
;
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
;    Here's the fixed version:
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


Gdb tells Rdi register holds 0x601030 after lea instruction has been executed. 

----------------------------------------------------------------------------------------
quci revie of relocation 

; it's usally done by the linker but in some cases it can be done by the
; executable itself.  The relocation sections contains relocation types, which describe what kind of relocation is
; required. If we examine the output below we see that 2 relocations are required to turn pie.o into an executable (pie_ex).
; We'll take a closer look at the columns in the relaction table in a moment but notice how the 32 bit addresses of lea and 
; printf call in pie.o that the relocation entries point at are both set to zero.
