  POSITION-INDEPENDENT CODE (PIC)/POSITION-INDEPENDENT EXECUTABLE (PIE) ON UBUNTU LINUX 5.8.0-44-generic X86_64
  
  16.3.2020

  In this tutorial we'll be taking a look at position independent code also known as pic, an interesting feature, 
  which is inherent in nearly all of the today's programs with programs running on embedded systems as an 
  exception. I originally ran into this this feature while trying to assemble example.asm below the way I'd been 
  taught. I thought it deserved some attention so I decied to write a tutorial about it. So without further ado, 
  let's dig right into it!
  
  We're going to use the following assembly program as example

  cat example.asm
   -----------------------------------
  | section .data                     |
  | 	msg: db "Hello world!",0x0a,0 |      
  |                                   |
  | section .text                     |
  |  	global main                   |
  |	extern printf                 |
  |                                   |
  | main: push rbp                    |
  |       mov  rbp, rsp               |
  |       lea  rdi, [msg]             |
  |       xor  rax, rax               |
  |       call printf                 |
  |                                   |
  |       xor  rax, rax               |
  |       leave                       |
  |       ret                         |
   -----------------------------------

  I proceeded by entering the following command and was shortly faced with an error message
 
  nasm -felf64 example.asm && gcc example.o -o example (we got this error message mostly likely with gcc-9.2.0 or gcc-9.1.0 (unlikely))
   ----------------------------------------------------------------------------------------------------------------------------------------
  | /usr/bin/ld: bill calculator.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIC |
  | /usr/bin/ld: final link failed: Nonrepresentable section on output                                                                     |
  | collect2: error: ld returned 1 exit status                                                                                             |
   ----------------------------------------------------------------------------------------------------------------------------------------
 
  (update: The error message has changed a bit and looks on gcc-7.5.0 - 9.3.0 like this)
   ----------------------------------------------------------------------------------------------------------------------------------------
  | /usr/bin/ld: example.o: relocation R_X86_64_32S against `.data' can not be used when making a PIE object; recompile with -fPIE         |
  | collect2: error: ld returned 1 exit status                                                                                             |
   ----------------------------------------------------------------------------------------------------------------------------------------
  
  The earlier error message mentions something about relocation so let's start from that.
 
  
  QUICK DESCRIPTION OF RELOCATION
 
  Relocation is a description for an address correction. It's an important piece of information which is processed
  later on by the static linker and possibly by the dynamic linker  
  
  
  
  
  
  It's required because the assembler doesn't consern
  itself with matters such as the possible distribution of the source code into several files, the use of
  libraries, the initialization code which is resposible for prepearing the environment the code holds 
  assumptions of or the cleanup code. These are all matters among others that will determine which addresses 
  are going to be used in the executable and they are left to the linker to be solved. The assemblers main task 
  is to translate assembly into machine code. The linker on the other hand has no knowlegde of assembly nor
  source code and therefore needs hints on where the the addresses that need to be fixed are located. This is
  where relocations come into the picture. The assembler generates a relocation table which it injects into
  the object file along with rest of code, data...
  
  The relocation table of example.o
 
  readelf -r example.o
   ----------------------------------------------------------------------------------
  | Relocation section '.rela.text' at offset 0x340 contains 2 entries:              |
  |   Offset          Info           Type           Sym. Value    Sym. Name + Addend |
  | 000000000008  00020000000b R_X86_64_32S      0000000000000000 .data + 0          |   
  | 000000000011  000500000009 R_X86_64_GOTPCREL 0000000000000000 printf - 4         |  
   ----------------------------------------------------------------------------------
 
  Offset = The offset the relocatable address in main, example.asm
  
  	If we turn over to the disassembled example.o, we see that both addresses specified in the
  	relocation table are preset to zero (00 00 00 00).
 
  	objdump -d -Mintel example.o
  	 ----------------------------------------------------------------------------------
  	|  example.o:     file format elf64-x86-64                                         |     
  	|                                                                                  |
  	|                                                                                  |
  	| Disassembly of section .text:                                                    |
  	|                                                                                  |
  	| 0000000000000000 <main>:                                                         |
  	|    0: 55                    push   rbp                                           |        
  	|    1: 48 89 e5              mov    rbp,rsp                                       |
  	|    4: 48 8d 3c 25 00 00 00  lea    rdi,ds:0x0                                    |
  	|    b: 00                                                                         |
  	|    c: 48 31 c0              xor    rax,rax                                       |
  	|    f: ff 15 00 00 00 00     call   QWORD PTR [rip+0x0]        # 15 <main+0x15>   |
  	|   15: 48 31 c0              xor    rax,rax                                       |
  	|   18: c9                    leave                                                |
  	|   19: c3                    ret                                                  | 
   	 ----------------------------------------------------------------------------------
  
  Info = Index of symbol in the symbol table and architecture-dependent details, used for calculating the address 
  Type = Type of the symbol? 
  
  	R_X86_64_32S
 
  	This relocation type means take the value (00 00 00 00) at the offset (000000000008), add the Sym. Value
  	to it, trunctate the result to a 32 bit value and finally check that that resulting value sign-extends to
  	the original value (00 00 00 00 or the result?). The sign-extension is perhaps checked to verified that the
  	program doesn't exceed the capability of 32 bit absoluted addressing. If the size of the code exceeds 2 GiB
  	some addresses of data or functions may lie too far from where they are referenced (code model?). Memory model     (IS LEA INSTRUCTION RELATIVE OR ABSOLUTE???)
  	and conanonical addresses?
 
  	R_X86_64_GOTPCREL
 
  	The calculation done by the R_X86_64_GOTPCREL relocation gives the difference between the location in the GOT 
  	where the symbol's address is given and the location where the relocation is applied. The address of prinft
  	in the got table is patched into main where printf is called. If we look at the disassembled example.o below 
  	we see that the byte at offset f of main consists of ff. This is the opcode for the 32 bit relative jump, 
  	which is used in the small code model (default), in code that's under 2 Gib in size.  
  
  Sym. Value = is equal to Sym. Name + Append and represent the current false address? 
  Sym. Name + Addend = For printing purposes.
 
  	Symbol table of example.o
 
  	nm --debug-syms example.o
  	 ----------------------------------------------------------------------------------
  	| 0000000000000000 d .data                                                         |
  	| 0000000000000000 a example.asm                                                   |
  	| 0000000000000000 T main                                                          |
  	| 0000000000000000 d msg                                                           |
  	|                  U printf                                                        |
  	| 0000000000000000 t .text                                                         |
  	 ----------------------------------------------------------------------------------
 
        d = The symbol is in the initialized data section. 
        U = The symbol is undefined. 

 
  
  At first I was tempted to write a c++ program that could solve the relocations, but then I realised it would not have been able
  to solve all of them since the the dynamic linker plaied a part. Anyways as I was writing the c++ code I got a picture of how the
  static linker works and I'd like to share it with you.
 
  The gcc linker uses the ld linker for linking. The ld linker in turn uses a linker script for assembling the executable. The command
  "ld --verbose" will print the linker script. If we review the linker script we'll see the search directories which ld linkers go through
  as it searches for the sections, which are required for the creating the executable. As we continue reading the linker script we'll see 
  the load address, which in this case is 0x400000. After that comes the we'll see the sections in the order they are going to appear in the 
  executable. The input sections are mapped to output sections. The output sections are grouped into segments, some of which are loaded to
  memory (ram) as the program is launched. Padding is used to align some of the content to increase effiency.
  
  
  WHAT IS PIC/PIE?
  
  Position-independent code as the name implies is code that doesn't restrict itself from being loaded to more than one (prefered) address.
  It's actually a few decade old solution to the a problem caused by the continious modification of programs and the practice of running 
  multiple programs at the same time and the possible memory fragmentation followed by it. The advent of mmu and virtual memory tossed pic
  into the dark but it didn't take long before it made itself back to the surface disguised as a library which comes in two different types,
  namely statics ones and shared/dynamic ones. The static library is linked to the program before execution. The advantage of using static
  libraries is sligthy faster exectution speed and the main disadvantage is larger executables. Shared/dynamic libraries on the other hand
  are not linked to the program prior execution. The advantages are smaller executables, code sharing and aslr and the dissadantage is slighty
  slower execution speed. A well know implementation of pic was called load-time relocation. In load-time relocation shared/dynamic libraries 
  are loaded onto memory and once loaded linked to the program. The disadvantage is that the libraries are not truly sharable since every 
  program needs their own copy of the library which makes memory usage inefficient and the loading prosedure every program had to through was  
  a performance penalty hit. A tehnique called pic was suggested as a solution. Pic allowed one single copy of a library to be shared by multiple 
  programs. In pic the references to global data and functions are routed via global offset table (got) and prosedure linkage table (plt). The
  addresses of global data are patched into the got by the dynamic linker and ... . The address of rip (instruction pointer) was obtained in a
  rather funky way, by calling a function whose soley purpose was to load the next instruction (return address) in the caller function from stack
  to a register and return back to caller function which added an offset to access either got or plt. 
  
  call funky
  add  rax, offset
  mov  rbx, [rax]
  
  funky: pop rax, [rsp]
         ret
  
  The advantages of pic must have lead to the
  neglection of load-time relocation since pic made it to x86_64 and was actually improved by the x86_64 architecture. Now the rip register is
  accessible ... . Later it became common practice to make the programs (non-library ones) themselves pic or pie as they were called and this
  allowed for address space layout randomization (aslr) to be applied, a technique that made exploiting vulnerabilites harder. Pic appears to
  be used a generic for code where the tehnique is applied whereas pie is exlusively used for non-libraries. Nowdays 2 types of shared/dynamic
  libraries are used on Linux; dynamically linked libraries and dynamically loaded libraries. We already covered dynamically linked libraries.
  The loading and linking of dynamically loaded libraries are managed partly by the programs themselves via requests and they are commonly used 
  in plugin programming. Pic/Pie has in today's programming and is pretty much the norm
  
  
  ROOT OF THE PROBLEM
  
  Pic/pie has 
 
  If the pie.o were to be linked into an ordinary executable that was based on 32 bit absolute addressing and loaded under the 2 GiB limit at a known load
  address, the addresses in pie.o would be resolved according to the respective relocation entries. It's not though cause the linker I was using was
  configured with --enable-default-pie flag and due this expected an object file that could be linked into a position independent executable (pie). Pie 
  is based on relative addressing and can thus be loaded anywhere in the memory, above the 2 GiB limt if prefered. In short there's a conflict between
  the linkers assumption about the code and the actual code. The code I wrote doesn't support pie. The error message mentions something about -fPIC, where
  PIC stands for postion independent code. This is C/C++ compiler flag used for compiling the source code into a pic supporting object file. Pic appears to
  be used as generic term for exectuables which are based on relative addresses whereas pie is exlusivly used for executables that aren't libraries. The
  distinction is clearer in compiling C/C++ where -fPIE flag is used for non-libraries and -fPIC flag for libraries. I still don't know how to interpret 
  the "/usr/bin/ld: final link failed: Nonrepresentable section on output" in the error message.
 
  
  SOLUTION
 
  We've 2 options 
 
  1. Leave the code as it is and override the default behaviour of the linker to get a non-PIE.
 
     nasm -felf64 example.asm
     
     objdump -d -Mintel example.o
     ...
     
     gcc -no-pie example.o
     
     objdump -d -Mintel a.out
     ...
     
     file a.out
      ---------------------------------------------------------
     | a.out: ELF 64-bit LSB executable,                       |
     | x86-64, version 1 (SYSV),                               |
     | dynamically linked,                                     |
     | interpreter /lib64/ld-linux-x86-64.so.2,                |
     | BuildID[sha1]=33d80bdfdf782e7c15995f35950aa5fc1b0f05f7, |
     | for GNU/Linux 3.2.0, not stripped                       |
      --------------------------------------------------------- 
     
     If you now examine a.out you'll notice that the addresses have been fixed
     (according to the earlier relocation table). What you'll also notice is that the 
     opcode for call has changed from an absolute call (ff) to a relative call (e8). 
     Yes the rip register in example.o is used for calculating the address but we end 
     up with an absolute address. This was not possible on architecures before x64. I
     guess e8 is more efficient.
 
     objdump -d -Mintel a.out
      --------------------------------------------------------------------------------
     | 00000000004004f0 <main>:                                                       |
     |   4004f0: 55                    push   rbp                                     |
     |   4004f1: 48 89 e5              mov    rbp,rsp                                 |
     |   4004f4: 48 8d 3c 25 30 10 60  lea    rdi,ds:0x601030                         |
     |   4004fb: 00                                                                   |
     |   4004fc: 48 31 c0              xor    rax,rax                                 |
     |   4004ff: e8 ec fe ff ff        call   4003f0 <printf@plt>                     | (THIS LOOKS WEIRD TOO!!! WE SHOULD GET CALLQ WITH NON-PIE FLAG)
     |   400504: 48 31 c0              xor    rax,rax                                 | (CHECK THE OUTPUT OF OBJDUMP AND SEE IF ITS AN ASSEMBLER/LINKER MATTER)
     |   400507: c9                    leave                                          |
     |   400508: c3                    ret                                            |
     |   400509: 0f 1f 80 00 00 00 00  nop    DWORD PTR [rax+0x0]                     |
      --------------------------------------------------------------------------------
  
 2.  Make the necessary changes in example.asm to eventually get a tasty pie

     We've 2 solutions for the error presented in the earlier error message

     1. 32 bit absolute addressing
        	
        lea rdi, [msg] --> lea rdi, [rel msg]
                         
        The rel keyword in the instruction can be left out if we add the "default rel"
        directive somewhere in pie.asm, between the sections.

        rel means the rip (instruction pointer) register is used to for calculating
        the address of msg?

     2. 64 bit absolute addressing

        lea rdi, [msg] -> mov rdi, qword msg 

        ...
           
    Now if we give it a try

    nasm -felf64 example.asm && gcc example.o
    
    We get the following error message (we got this error message mostly likely with gcc-9.2.0 or gcc-9.1.0(unlikely))
     ------------- ---------------------------------------------------------
    | ./a.out: Symbol `printf' causes overflow in R_X86_64_PC32 relocation |  
    | Segmentation fault (core dumped)                                     |
     ----------------------------------------------------------------------

    (update: The error message has changed a bit and looks like this on gcc-7.5.0 - 9.3.0)
     ------------------------------------------------------------------------------------------------------------------------------------------------------
    | /usr/bin/ld: example.o: relocation R_X86_64_PC32 against symbol `printf@@GLIBC_2.2.5' can not be used when making a PIE object; recompile with -fPIE |
    | /usr/bin/ld: final link failed: bad value                                                                                                            |
    | collect2: error: ld returned 1 exit status                                                                                                           |
     ------------------------------------------------------------------------------------------------------------------------------------------------------

    Again we've 2 solutions for the this error

    32 bit relative addressing

    1. call printf --> call [rel printf WRT ..got] (rel can be omitted if we added "default rel" directive earlier)

       In this version the address of printf is patched into the global offsets table (got) at load time and since 
       the got is located at a known offset all we need to do is to dereference (PTR) the pointer in got to call printf.

       nasm -felf64 example.asm
       
       objdump -d -Mintel example.o
        ---------------------------------------------------------------------------
       | ...                                                                       |
       |                                                                           |
       | ff 15 00 00 00 00    	call   QWORD PTR [rip+0x0]        # 14 <main+0x14> |
       |                                                                           |
       | ...                                                                       |
        ---------------------------------------------------------------------------
        
       readelf -r example.o
        ----------------------------------------------------------------------------------
       | Relocation section '.rela.text' at offset 0x340 contains 2 entries:              |
       |   Offset          Info           Type           Sym. Value    Sym. Name + Addend |
       | 000000000007  000200000002 R_X86_64_PC32     0000000000000000 .data - 4          |
       | 000000000010  000500000009 R_X86_64_GOTPCREL 0000000000000000 printf - 4         |
       | palmer@palmer-Yoga-Slim-7-Carbon-13ITL5:~/Desktop$ readelf -r a.out              |
        ----------------------------------------------------------------------------------
        
       gcc example.o 
       
       readelf -r a.out
        -------------------------------------------------------------------------------------------------
       | Relocation section '.rela.dyn' at offset 0x490 contains 9 entries:                              |
       |   Offset          Info           Type           Sym. Value    Sym. Name + Addend                |
       | 000000003de8  000000000008 R_X86_64_RELATIVE                    1140                            |
       | 000000003df0  000000000008 R_X86_64_RELATIVE                    1100                            |
       | 000000004008  000000000008 R_X86_64_RELATIVE                    4008                            |
       | 000000003fd0  000100000006 R_X86_64_GLOB_DAT 0000000000000000 _ITM_deregisterTMClone + 0        |
       | 000000003fd8  000200000006 R_X86_64_GLOB_DAT 0000000000000000 printf@GLIBC_2.2.5 + 0            |
       | 000000003fe0  000300000006 R_X86_64_GLOB_DAT 0000000000000000 __libc_start_main@GLIBC_2.2.5 + 0 |
       | 000000003fe8  000400000006 R_X86_64_GLOB_DAT 0000000000000000 __gmon_start__ + 0                |
       | 000000003ff0  000500000006 R_X86_64_GLOB_DAT 0000000000000000 _ITM_registerTMCloneTa + 0        |
       | 000000003ff8  000600000006 R_X86_64_GLOB_DAT 0000000000000000 __cxa_finalize@GLIBC_2.2.5 + 0    |
        -------------------------------------------------------------------------------------------------
       
       objdump -d -Mintel a.out
        -----------------------------------------------------------------------------------------
       | ...                                                                                     |
       |                                                                                         |
       | ff 15 74 2e 00 00    	call   QWORD PTR [rip+0x2e74]        # 3fd8 <printf@GLIBC_2.2.5> |
       |                                                                                         |
       | ...                                                                                     |
        -----------------------------------------------------------------------------------------       
       
       Interestingly call opcode ff (absolute) is use instead of e8 (relative)

    2. call printf --> call printf WRT ..plt

       Here we use procedure linkage table (plt) as an indirection to speed up load time. The libaries are loaded unless
       they are already loaded (by some other program) in the same way with one exception; the addresses to the library
       functions are not resolved (fixed) until the functions are called. This is called lazy binding and it's handy in
       situations when we don't know if the function is going to be called at all. The first time printf is called an entry
       in plt is called in which a jump is made with a dereferenced got pointer to a point in plt where the resolver is prepeared
       with some arguments after which a jump is maded to the first entry of plt where the resolver is called. The resolver
       resolves the address of prinft and patches it into got and after that calls printf. Next time printf is called the
       same entry in plt is called once again but when the jump with the dereferenced got pointer is made, we end up in
       prinft instead of plt. The code in the plt goes by the name: stubb code and the whole back and forth jump process 
       is also called tramboline.  
           
       nasm felf64 example.asm
       
       objdump -d -Mintel example.o
        ----------------------------------------------
       | ...                                          |
       |                                              |
       | e8 00 00 00 00       	call   13 <main+0x13> |
       |                                              |
       | ...                                          |
        ----------------------------------------------
                
       gcc example.o
       
       objdump -d -Mintel a.out
        -------------------------------------------------
       | ...                                             |
       |                                                 |
       | e8 bd fe ff ff       	call   1030 <printf@plt> |
       |                                                 |
       | ...                                             |
        -------------------------------------------------      

       Whereas here call opcode e8 (relative) is used instead of ff (absolute)
    
       As we see from the previous instruction a jump is made to the prinft entry of plt at line 1030
       
       objdump -D -Mintel a.out
       ...
       
       Disassembly of section .plt:

       0000000000001020 <.plt>:
            1020:      ff 35 9a 2f 00 00    	push   QWORD PTR [rip+0x2f9a]        # 3fc0 <_GLOBAL_OFFSET_TABLE_+0x8>
            1026:      ff 25 9c 2f 00 00    	jmp    QWORD PTR [rip+0x2f9c]        # 3fc8 <_GLOBAL_OFFSET_TABLE_+0x10>
            102c:      0f 1f 40 00          	nop    DWORD PTR [rax+0x0]

       0000000000001030 <printf@plt>:
            1030:      ff 25 9a 2f 00 00    	jmp    QWORD PTR [rip+0x2f9a]        # 3fd0 <printf@GLIBC_2.2.5>
            1036:      68 00 00 00 00       	push   0x0
            103b:      e9 e0 ff ff ff       	jmp    1020 <.plt>
            
       ...
       
       Recall that rip (instruction pointer) register points to the next instruction (1036). At line 1030
       an offset of 0x2f9a is added to 1036 wich gives us 3fd0. This line will take us to a got entry.
       
       objdump -D -Mintel a.out
       ...
       
       Disassembly of section .got:

       0000000000003fb8 <_GLOBAL_OFFSET_TABLE_>:
            3fb8:      c8 3d 00 00          	enter  0x3d,0x0
	        ...
            3fd0:      36 10 00             	adc    BYTE PTR ss:[rax],al
	        ...
       ...
       
       The content on line 3fd0 is read as 1036 (DON'T MIND THE INSTRUCTION! OBJDUMP INTERPRETS 1036 AS FOR AN INSTRUCTION)
       
       So the previously instruction we looked at turns from
       
       jmp QWORD PTR [rip+0x2f9a] -> jmp 1036
       
       On line 1036 the index of the relocation of address at line 3fd0 in the relocation table is pushed onto the stack.
       
       readelf -r a.out
       ...
       
       Relocation section '.rela.plt' at offset 0x550 contains 1 entry:
          Offset          Info           Type           Sym. Value    Sym. Name + Addend
       000000003fd0  000200000007 R_X86_64_JUMP_SLO 0000000000000000 printf@GLIBC_2.2.5 + 0
       
       After that a jump is made to the beginning of plt
       
       pushed an address of a structure that indentifies the location of the caller?? (on phone)
       
       After that a jump is made through the got to the dynamic loader (dynamic linker = .interp)
       
       https://www.gabriel.urdhr.fr/2015/01/22/elf-linking/#calling-the-interpreter

       Here's the fixed version

       cat example.asm
        -----------------------------------
       | section .data                     |
       |     msg: db "Hello world!",0x0a,0 |      
       |                                   |
       | section .text                     |
       |     global main                   |
       |     extern printf                 |
       |                                   |
       | main: push rbp                    |
       |       mov  rbp, rsp               |
       |       lea  rdi, [rel msg]         |
       |       xor  rax, rax               |
       |       call [rel printf WRT ..got] |
       |                                   |
       |       xor  rax, rax               |
       |       leave                       |
       |       ret                         |
        -----------------------------------
     
       nasm -felf64 example.asm && gcc example.o 
    
       file a.out
        ---------------------------------------------------------
       | a.out: ELF 64-bit LSB shared object, x86-64,            |
       | version 1 (SYSV),                                       |
       | dynamically linked,                                     |
       | interpreter /lib64/ld-linux-x86-64.so.2,                |
       | BuildID[sha1]=2b5bb3de0bdc4c9df3883e3b788dd28aa8559381, | 
       | for GNU/Linux 3.2.0, not stripped                       |
        ---------------------------------------------------------
       
       ./a.out
        ---------------------------------------------------------
       | Hello World!                                            |               
        ---------------------------------------------------------



























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

----------------------------------------------------------------------------------------------------------------------------------
https://eli.thegreenplace.net/2011/11/03/position-independent-code-pic-in-shared-libraries
https://eli.thegreenplace.net/2011/08/25/load-time-relocation-of-shared-libraries/
https://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models
https://eli.thegreenplace.net/2011/11/11/position-independent-code-pic-in-shared-libraries-on-x64
https://stackoverflow.com/questions/43367427/32-bit-absolute-addresses-no-longer-allowed-in-x86-64-linux/46493456
https://security.stackexchange.com/questions/168101/return-to-libc-finding-libcs-address-and-finding-offsets
https://www.technovelty.org/category/c.html

PLT VS GOT
https://blog.fxiao.me/got-plt/
https://systemoverlord.com/2017/03/19/got-and-plt-for-pwning.html
https://ctf101.org/binary-exploitation/what-is-the-got/
https://ctf101.org/binary-exploitation/relocation-read-only/
https://ilivetoseek.wordpress.com/2011/10/24/how-gotplt-work/amp/
https://www.technovelty.org/linux/plt-and-got-the-key-to-code-sharing-and-dynamic-libraries.html
https://stackoverflow.com/questions/56404855/how-can-i-call-printf-normally-in-assembly-without-plt-but-just-call-printf-wit/56405510

  https://reverseengineering.stackexchange.com/questions/16841/address-to-file-offset
  https://stackoverflow.com/questions/2187484/why-is-the-elf-execution-entry-point-virtual-address-of-the-form-0x80xxxxx-and-n
  https://stackoverflow.com/questions/38549972/why-elf-executables-have-a-fixed-load-address
  https://stackoverflow.com/questions/1685483/how-can-i-examine-contents-of-a-data-section-of-an-elf-file-on-linux
  https://stackoverflow.com/questions/18296276/base-address-of-elf
  https://stackoverflow.com/questions/16847741/processing-elf-relocations-understanding-the-relocs-symbols-section-data-an

  https://stackoverflow.com/questions/46123505/assembling-with-gcc-causes-weird-relocation-error-with-regards-to-data
