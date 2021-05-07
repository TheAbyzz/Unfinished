pic on x86_64
https://www.technovelty.org/c/position-independent-code-and-x86-64-libraries.html

pic (32 or 64?)
https://fasterthanli.me/series/making-our-own-executable-packer/part-3

elf relocations
https://fasterthanli.me/series/making-our-own-executable-packer/part-4

shared library example
https://fasterthanli.me/series/making-our-own-executable-packer/part-5

static libary is pic after the COMPILER (NOT ASSEMBLER) has compiled it. Linker resolves the addresses
https://stackoverflow.com/questions/57649452/why-must-shared-libraries-be-position-independent-while-static-libraries-dont

difference between dynamically linked and loaded shared library
https://cs.stackexchange.com/questions/92484/difference-between-dynamic-loading-and-dynamic-linking-in-the-os

pic/pie on 32 bit
https://eli.thegreenplace.net/2011/11/03/position-independent-code-pic-in-shared-libraries

linux uses shared objrects .so and windows dynamically linked libraries .DLL
https://stackoverflow.com/questions/56899488/what-is-the-difference-between-shared-and-dynamic-libraries-in-c

load-time relocation shared library (32 bit)
https://eli.thegreenplace.net/2011/08/25/load-time-relocation-of-shared-libraries/

pic (32 bit)
https://eli.thegreenplace.net/2011/11/03/position-independent-code-pic-in-shared-libraries/

pic (64 bit)
https://eli.thegreenplace.net/2011/11/11/position-independent-code-pic-in-shared-libraries-on-x64

load-time relocation is not possible on 64 bit anymore
https://www.reddit.com/r/programming/comments/jtykm/loadtime_relocation_of_shared_libraries/

32 bit code vs 64 bit code
https://www.tfzx.net/article/29772.html

Anatomy of Linux dynamic libraries
https://developer.ibm.com/tutorials/l-dynamic-libraries/

relocation against data (our problem might be explained here)
https://stackoverflow.com/questions/58106310/nasm-linux-shared-object-error-relocation-r-x86-64-32s-against-data            <---------------------

pic explained
https://hackaday.io/project/26354-fieldkit/log/167486-position-independent-code
 
about ELF – PIE, PIC and else
https://codywu2010.wordpress.com/2014/11/29/about-elf-pie-pic-and-else/

pie
https://stackoverflow.com/questions/43367427/32-bit-absolute-addresses-no-longer-allowed-in-x86-64-linux          

relative addressing
https://stackoverflow.com/questions/54745872/how-do-rip-relative-variable-references-like-rip-a-in-x86-64-gas-intel-sy

rip relative addressing in nasm
https://stackoverflow.com/questions/31234395/why-use-rip-relative-addressing-in-nasm

-fpie option
https://stackoverflow.com/questions/2463150/what-is-the-fpie-option-for-position-independent-executables-in-gcc-and-ld

What do R_X86_64_32S and R_X86_64_64 relocation mean?
https://stackoverflow.com/questions/6093547/what-do-r-x86-64-32s-and-r-x86-64-64-relocation-mean

c++ linking explained
https://stackoverflow.com/questions/12122446/how-does-c-linking-work-in-practice/30507725#30507725

How to make an executable ELF file in Linux using a hex editor?
https://stackoverflow.com/questions/26294034/how-to-make-an-executable-elf-file-in-linux-using-a-hex-editor/30648229#30648229

Nasm - Symbol `printf' causes overflow in R_X86_64_PC32 relocation
https://stackoverflow.com/questions/48071280/nasm-symbol-printf-causes-overflow-in-r-x86-64-pc32-relocation

x86-64 assembly from scratch (what are the flags -Wall -Wextra -Werror)
https://www.conradk.com/codebase/2017/06/06/x86-64-assembly-from-scratch/

check the 16 byte stack aligment requirment, it's needed for some instrunctions
is push rbp mov rbp, rsp always required
https://cs.lmu.edu/~ray/notes/nasmtutorial/
stack frame
in 64 bit intel assembly language progamming for linux.pdf page 108
push rbp mov rbp, rsp can be omitted
WE SUBTRCT OR PUSH BEFORE CALL AND ADD OR POP AFTER CALL
push or sub is not needed for printf
it's only needed with floating point instructions

section .data
	msg: db "Hello world!",0
	fmt: db "%lf",0x0a,0
	float1: dq 1.5         ; could we align the memory here to avoid the 16 byte alignment in main?

section .text
	global main
	extern printf

main: push  rbp
      mov   rbp, rsp
      lea   rdi, [fmt]
      movsd xmm0, [float1] ; movq xxm0, qword [float1], movsd (64), movss (32)
      mov   rax, 1
      call  printf

      xor  rax, rax
      leave
      ret

how do we determine the precsision, now we get 1.5000000
what is p.133 all about? movups and ...

According to the x86 ABI, EBX, ESI, EDI, and EBP are callee-save registers and EAX, ECX and EDX are caller-save registers.
this means library functions may destroy eax, ecx and edx so the call has to save them
The other ones are not touched unless the programmer writes a function which does that
they dont have to be saved
read through the SYS V ABI x64
https://stackoverflow.com/questions/34100466/why-is-the-value-of-edx-overwritten-when-making-call-to-printf
https://cs.lmu.edu/~ray/notes/nasmtutorial/

add some flexibility to the program 
n = scanf("%ld, %hd"); return value 2 if sucessfull
what's interesting is that it returns 2 even when more than 2 parameters are given

check that the division is done properly, what quotent and remainder registers should we use
ax (16) <- +8 ah (8) <- +8 al (0)
clear rdx register if needed, may cause a float exception

times directive is causing problems
if kWh_array: resw nr_of_samples is replaced by kWh_array: times 3 resw 1 or kWh_array: times 3 dw 0
the first element becomes 1280 instead of 1500 in the second loop
elements are inserted in the following order: 1500, 2000, 2500
the 2 last elements remain the same but the first one changes?
times has cause problems earlier, check this out!

dll hell

the difference between felf, elf and hex file?

readelf, objdump, nm

https://www.tutorialspoint.com/assembly_programming/assembly_registers.htm

what value is the segment egister ds holding?

are the addresses of the segment addresses put into segment registers when the library is loaded

Apart from the DS, CS and SS registers, there are other extra segment registers - ES (extra segment), FS and GS, which provide additional segments for storing data.

In assembly programming, a program needs to access the memory locations. All memory locations within a segment are relative to the starting address of the segment. A segment begins in an address evenly divisible by 16 or hexadecimal 10. So, the rightmost hex digit in all such memory addresses is 0, which is not generally stored in the segment registers.

The segment registers stores the starting addresses of a segment. To get the exact location of data or instruction within a segment, an offset value (or displacement) is required. To reference any memory location in a segment, the processor combines the segment address in the segment register with the offset value of the location.

https://stackoverflow.com/questions/38277327/assembly-segment-register-offset-register
ds holds the number of the block which is multiplied with 16 (10h) afterwich the offset is added (+) to the register to get the address of the desired
data item

https://stackoverflow.com/questions/9341212/elf-shared-object-in-x86-64-assembly-language