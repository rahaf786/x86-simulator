.global  main
.data
ten: .long 10
counter: .long 0
itoa_string: .ascii "          \n"
sjsuprompt: .ascii "(sjsu) "
instruction: .ascii "                "
ilen: .long 0
alu: .long 0
output_mode: .long 0     # 0 = dec, 1 = hex
.text
main:
    movl   $4,%eax
    movl   $1,%ebx
    movl   $sjsuprompt,%ecx
    movl   $7,%edx
    int    $0x80

    movl   $3,%eax
    movl   $0,%ebx
    movl   $instruction,%ecx
    movl   $16,%edx
    int    $0x80
    decl   %eax
    movl   %eax,ilen

    cmpl   $0x20766f6d,instruction
    je     do_mov
    cmpl   $0x20646461,instruction
    je     do_add
    cmpl   $0x206c756d,instruction
    je     do_mul
    cmpl   $0x20627573,instruction
    je     do_sub
    cmpl   $0x206f7571,instruction
    je     do_quo
    cmpl   $0x206d6572,instruction
    je     do_rem
    cmpl   $0x20776f70,instruction
    je     do_pow
    cmpl   $0x78656820,instruction
    je     do_hex
    cmpl   $0x63656420,instruction
    je     do_dec
    cmpl   $0x74697865,instruction   # "exit"
    je     do_exit
    jmp    main

do_mov:
    call   atoi
    movl   counter,%eax
    movl   %eax,alu
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_add:
    call   atoi
    movl   counter,%eax
    addl   %eax,alu
    movl   alu,%eax
    movl   %eax,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_mul:
    call   atoi
    movl   counter,%eax
    imull  alu,%eax
    movl   %eax,alu
    movl   %eax,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_sub:
    call   atoi
    movl   alu,%eax
    subl   counter,%eax
    movl   %eax,alu
    movl   %eax,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_quo:
    call   atoi
    movl   alu,%eax
    cdq
    idivl  counter
    movl   %eax,alu
    movl   %eax,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_rem:
    call   atoi
    movl   alu,%eax
    cdq
    idivl  counter
    movl   %edx,alu
    movl   %edx,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_pow:
    call   atoi
    movl   alu,%ecx
    movl   counter,%ebx
    cmpl   $0,%ebx
    je     pow_zero_case
    movl   $1,%eax
pow_loop:
    imull  %ecx,%eax
    decl   %ebx
    cmpl   $0,%ebx
    jg     pow_loop
    jmp    pow_done
pow_zero_case:
    movl   $1,%eax
pow_done:
    movl   %eax,alu
    movl   %eax,counter
    call   itoa
    movl   $4,%eax
    movl   $1,%ebx
    movl   $itoa_string,%ecx
    movl   $11,%edx
    int    $0x80
    jmp    main

do_hex:
    movl $1, %eax
    movl %eax, output_mode
    movl alu, %eax
    movl %eax, counter
    call itoa
    movl $4, %eax
    movl $1, %ebx
    movl $itoa_string, %ecx
    movl $11, %edx
    int $0x80
    jmp main

do_dec:
    movl $0, %eax
    movl %eax, output_mode
    movl alu, %eax
    movl %eax, counter
    call itoa
    movl $4, %eax
    movl $1, %ebx
    movl $itoa_string, %ecx
    movl $11, %edx
    int $0x80
    jmp main

do_exit:
    movl $1, %eax
    movl $0, %ebx
    int $0x80

atoi:
    movl   ilen,%esi
    decl   %esi
    movl   $1,%ebx
    movl   $0,counter
atoi_loop:
    movl   $0,%eax
    movb   instruction(%esi),%al
    subb   $'0',%al
    imull  %ebx
    addl   %eax,counter
    imull  $10,%ebx,%ebx
    decl   %esi
    cmpl   $4,%esi
    jge    atoi_loop
    ret

itoa:
    movl output_mode, %ebx
    cmpl $0, %ebx
    jne itoa_hex
    movl counter, %eax
    movl $0x20202020,itoa_string
    movl $0x20202020,itoa_string+4
    movw $0x2020,itoa_string+8
    leal itoa_string+9, %edi
itoa_dec_loop:
    movl $0, %edx
    idivl ten
    addl $'0', %edx
    movb %dl, (%edi)
    decl %edi
    cmpl $0, %eax
    jg itoa_dec_loop
    ret

itoa_hex:
    movl counter, %eax
    movl $0x20202020,itoa_string
    movl $0x20202020,itoa_string+4
    movw $0x2020,itoa_string+8
    leal itoa_string+9, %edi
itoa_hex_loop:
    movl $0, %edx
    movl $16, %ecx
    divl %ecx
    cmpl $10, %edx
    jl hex_digit
    addl $'A'-10, %edx
    jmp store_hex
hex_digit:
    addl $'0', %edx
store_hex:
    movb %dl, (%edi)
    decl %edi
    cmpl $0, %eax
    jg itoa_hex_loop
    ret

