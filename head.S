
.section .phys.text

.code32

    .global huge_page_check;
    .type huge_page_check, %function;
huge_page_check:
    movl $0x80000001, %eax
    cpuid
    andl $0x04000000, %edx
    jz   1f
    ret
1:
    movl $huge_page_error_string, %ebx
    movl $huge_page_error_size, %ecx
    call print_string
    call hang

huge_page_error_string:
    .string "Huge page not supported by the processor"
    .set huge_page_error_size, . - huge_page_error_string
    .size huge_page_check, .-huge_page_check


    .global setup_pml4;
    .type setup_pml4, %function;
setup_pml4:
    call huge_page_check
    movl %cr0, %eax
    andl $0x7fffffff, %eax
    movl %eax, %cr0

    movl $boot_pml4, %edi
    movl $0x0, %edx
    movl $1024, %ecx
1:
    movl %edx, (%edi)
    addl $4, %edi
    loop 1b

    movl $boot_pdpt, %edi
    movl $1024, %ecx
1:
    movl %edx, (%edi)
    addl $4, %edi
    loop 1b

    movl $boot_pml4, %edi
    movl $boot_pdpt, %ecx
    orl  $0x7, %ecx
    movl %ecx, (%edi)
    movl %ecx, 0x800(%edi)
    movl %ecx, 4088(%edi)

    movl $_boot_pd, %ecx
    orl  $0x7, %ecx
    movl $boot_pdpt, %edi
    movl %ecx, (%edi)
    movl %ecx, 4080(%edi)
    addl $0x1000, %ecx
    movl %ecx, 8(%edi)
    addl $0x1000, %ecx
    movl %ecx, 16(%edi)
    addl $0x1000, %ecx
    movl %ecx, 24(%edi)

    /* Map first 4GiB into the _boot_pd. */
    movl $_boot_pd, %edi
    movl $2048, %ecx
    movl $0x87, %edx
2:
    movl %edx, (%edi)
    addl $0x200000, %edx
    addl $8, %edi
    loop 2b
    ret
    .size setup_pml4, .-setup_pml4


   .global common_init;
   .type common_init, %function;
common_init:
    /* Disable paging. */
    movl %cr0, %eax
    andl $0x7fffffff, %eax
    movl %eax, %cr0

    /* Initialize boot PML4 and switch to long mode. */
    call setup_pml4
    call enable_x64_mode
    lgdt _gdt64_ptr

    call syscall_enable
    ret
    .size common_init, .-common_init


    .global _start;
    .type _start, %function;
_start:
    /* Assume we are MultiBooted, e.g. by GRUB.
     * While not immediately checked, the magic number is checked prior to 
     * Multiboot dependent operations. */
    movl %eax, %edi /* multiboot_magic    */
    movl %ebx, %esi /* multiboot_info_ptr */

    /* Load kernel boot stack pointer. */
    leal boot_stack_top, %esp

    /* Reset EFLAGS register (also disables interrupts etc.). */
    pushl $0
    popf

    /* Already push parameters for calling boot_sys later. Push
     * them as 8 byte values so we can easily pop later. */
    pushl $0
    pushl %esi /* 2nd parameter: multiboot_info_ptr */
    pushl $0
    pushl %edi /* 1st parameter: multiboot_magic    */

    call common_init

    /* Reload CS with long bit to enable long mode. */
    ljmp $8, $_start64
    .size _start, .-_start



.code64

    .global _start64;
    .type _start64, %function;
_start64:
    /* Leave phys code behind and jump to the high kernel virtual address. */
    movabs $_entry_64, %rax
    jmp *%rax
.size _start64, .-_start64;

.section .boot.text

   .global _entry_64;
   .type _entry_64, %function;
_entry_64:
    /* Update our stack pointer. */
    movq $0xffffffff80000000, %rax
    addq %rax, %rsp
    addq %rax, %rbp

    /* Pop the multiboot parameters off. */
    pop %rdi
    pop %rsi

    /* Load our real kernel stack. */
    leaq kernel_stack_alloc + 4096, %rsp

    movabs $restore_user_context, %rax
    push %rax
    jmp boot_sys

    .size _entry_64, .-_entry_64

