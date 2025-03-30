/*
 * Calling convention for x86-64
 * For integer type, the next available register of the sequence %rdi,
 * %rsi, %rdx, %rcx, %r8 and %r9 are used for passing values. %rax and
 * %rdx are used for returning integer values. Pointers are considered
 * as integer type according to the ABI.
 */

.section .boot.text

.section .text

    .global out8;
    .type out8, %function;
out8:
    movq    %rdi, %rdx
    movq    %rsi, %rax
    outb    %al, %dx
    ret
    .size out8, .-out8


    .global out16;
    .type out16, %function;
out16:
    movq    %rdi, %rdx
    movq    %rsi, %rax
    outw    %ax, %dx
    ret
    .size out16, .-out16


    .global out32;
    .type out32, %function;
out32:
    movq    %rdi, %rdx
    movq    %rsi, %rax
    outl    %eax, %dx
    ret
    .size out32, .-out32


    .global in8;
    .type in8, %function;
in8:
    movq    $0, %rax
    movq    %rdi, %rdx
    inb     %dx, %al
    ret
    .size in8, .-in8


    .global in16;
    .type in16, %function;
in16:
    movq    $0, %rax
    movq    %rdi, %rdx
    inw     %dx, %ax
    ret
    .size in16, .-in16


    .global in32;
    .type in32, %function;
in32:
    movq    $0, %rax
    movq    %rdi, %rdx
    inl     %dx, %eax
    ret
    .size in32, .-in32

    .global getCacheLineSize;
    .type getCacheLineSize, %function;
getCacheLineSize:
    push    %rbx
    movl    $1, %eax
    cpuid
    movl    %ebx, %eax
    shrl    $8, %eax
    andl    $0xff, %eax
    shll    $3, %eax
    pop     %rbx
    ret
    .size, .-getCacheLineSize


    .global x64_install_gdt;
    .type x64_install_gdt, %function;
x64_install_gdt:
    lgdt    (%rdi)          # load gdtr with gdt pointer
    movw    $0x10, %ax      # load register ax with seg selector
    movw    %ax, %ds
    movw    %ax, %es
    movw    %ax, %ss
    movw    $0x0, %ax
    movw    %ax, %fs
    movw    %ax, %gs
    ret
    .size x64_install_gdt, .-x64_install_gdt


    .global x64_install_idt;
    .type x64_install_idt, %function;
x64_install_idt:
    lidt    (%rdi)
    ret
    .size x64_install_idt, .-x64_install_idt


    .global x64_install_ldt;
    .type x64_install_ldt, %function;
x64_install_ldt:
    lldt    %di
    ret
    .size x64_install_ldt, .-x64_install_ldt


    .global x64_install_tss;
    .type x64_install_tss, %function;
x64_install_tss:
    ltr     %di
    ret
    .size x64_install_tss, .-x64_install_tss


    .global int_00
    .type   int_00, %function
int_00:
    pushq $0x0
    /* Check CPL */
    testq   $3, 16(%rsp)
    jz      1f;
2:
    lea x64KSKernelPML4 - 0xffffffff80000000UL, %rsp
    movq %rsp, %cr3

    LOAD_USER_CONTEXT_OFFSET(4)
    movq (ksCurThread), %rsp
    addq $(512 + 22*8 - 6*8 + (4)*8), %rsp

    push    %rcx
    movq    $0x00, %rcx
    jmp     handle_interrupt
1:
    INT_HANDLE_COMMON_EXCEPT(number,except)
.size   int_00, . - int_00;



<int_00>:
	push   $0x0
	testq  $0x3,0x10(%rsp)
	
	je     ffffffff80801708 <int_00+0x34>
	lea    0xa03000,%rsp
	
	mov    %rsp,%cr3
	mov    0xffffffff80a0f760,%rsp
	
	add    $0x2a0,%rsp
	push   %rcx
	mov    $0x0,%rcx
	jmp    ffffffff80806d5d <handle_interrupt>
	mov    0x20(%rsp),%rsp
	push   %rcx
	mov    $0x0,%rcx
	jmp    ffffffff80806de5 <kernel_exception>
