ENTRY(_start)
KLOAD_PADDR = 0x00100000;
KLOAD_VADDR = (0xffffffff80000000 + 0x00100000);
/* WARNING: constants also defined in plat/machine/hardware.h */
OUTPUT_FORMAT(elf64-x86-64)
KERNEL_OFFSET = KLOAD_VADDR - KLOAD_PADDR;
PHDRS {
    phys PT_LOAD FILEHDR PHDRS ;
    boot PT_LOAD ;
    virt PT_LOAD ;
}
SECTIONS
{
    /* load kernel to 1M to avoid the famous IA-32 memory holes below */
    . = KLOAD_PADDR + SIZEOF_HEADERS;
    /* code/data only needed during bootstrapping, linked to physical addresses */
    .phys . :
    {
        *(.mbh)
        *(.phys.text)
        *(.phys.data)
        . = . + 1;
    } :phys
    .phys.bss ADDR(.phys) + SIZEOF(.phys) + 4K (NOLOAD) :
    {
        . = ALIGN(16);
        boot_stack_bottom = .;
        . = . + 2K;
        boot_stack_top = .;
        *(.phys.bss)
    } :phys
    . = ALIGN(4K) + KERNEL_OFFSET;
    . = . + ((ADDR(.phys) + SIZEOF(.phys)) & (4K - 1));
    .boot . : AT(ADDR(.boot) - KERNEL_OFFSET)
    {
        *(.boot.text)
        *(.boot.data)
    } :boot
    .boot.bss . (NOLOAD) : AT(ADDR(.boot.bss) - KERNEL_OFFSET)
    {
        *(.boot.bss)
    } :boot
    /* Align up so that the SKIM portion of the kernel is by itself
       on large pages */
    . = ALIGN(2M);
    ki_boot_end = .;
    ki_skim_start = .;
    . = . + ((ADDR(.boot) + SIZEOF(.boot)) & (8K - 1));
    .text . : AT(ADDR(.text) - KERNEL_OFFSET)
    {
        *(.text)
    } :virt
    .rodata . : AT(ADDR(.rodata) - KERNEL_OFFSET)
    {
        *(.rodata)
        *(.rodata.*)
    } :virt
    .skim_data . : AT(ADDR(.skim_data) - KERNEL_OFFSET)
    {
        *(.skim.data)
        *(.skim.data.*)
    } :virt
    .skim_bss . (NOLOAD) : AT(ADDR(.skim_bss) - KERNEL_OFFSET)
    {
        *(.skim.bss)
        *(.skim.bss.*)
    } :virt
    /* Align up so that the SKIM portion of the kernel is by itself
       on large pages */
    . = ALIGN(2M);
    ki_skim_end = .;
    .data . : AT(ADDR(.data) - KERNEL_OFFSET)
    {
        *(.data)
    } :virt
    .bss . (NOLOAD) : AT(ADDR(.bss) - KERNEL_OFFSET)
    {
        *(.bss)
        *(COMMON) /* fallback in case '-fno-common' is not used */
    } :virt
    . = ALIGN(4K);
    ._idle_thread . (NOLOAD): AT(ADDR(._idle_thread) - KERNEL_OFFSET)
    {
 __idle_thread_start = .;
        *(._idle_thread)
 __idle_thread_end = .;
    } :virt
    . = ALIGN(4K);
    ki_end = .;
    /DISCARD/ :
    {
        *(.eh_frame)
        *(.note.gnu.build-id)
        *(.comment)
    }
}
