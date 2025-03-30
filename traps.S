.section .text
.code64

// Handle Syscall (coming via sysenter)
// Assume following register contents when called:
//  RAX : syscall number
//  RCX : user ESP
//  RDX : user EIP (pointing to the sysenter instruction)
//  RSP : NULL
    .global handle_syscall;
    .type handle_syscall, %function;
handle_syscall:
    /* We need to save r11, rdx TLS_BASE and RSP */
    lea x64KSKernelPML4 - 0xffffffff80000000UL, %rsp
    movq %rsp, %cr3

    movq (ksCurThread), %rsp
    addq $(512 + 22*8 - 6*8 + (3)*8), %rsp


    push    %r11
    push    %rdx            # save FaultIP
    push    %rcx            # save RSP
    push    $-1             # set Error -1 to mean entry via syscall
    push    %rdx            # save FaultIP (which will need to be updated later)
    pushf                   # save RFLAGS
    orq     $0x200, (%rsp)  # set interrupt bit in save RFLAGS
    push    %r15            # save R15 (message register)
    push    %r9             # save R9 (message register)
    push    %r8             # save R8 (message register)
    push    %r10            # save R10 (message register)
    subq    $8, %rsp        # skip RDX
    push    %r14
    push    %r13
    push    %r12
    push    %rbp
    push    %rbx
    push    %rax            # save RAX (syscall number)
    push    %rsi            # save RSI (msgInfo register)
    push    %rdi            # save RDI (capRegister)

    // switch to kernel stack
    leaq    kernel_stack_alloc + (1 << 12), %rsp

    // RSI, RDI are already correct for calling c_handle_syscall
    movq %rax, %rdx
    // gtfo to C land, we will not return
    call    c_handle_syscall
    .size handle_syscall, .-handle_syscall
