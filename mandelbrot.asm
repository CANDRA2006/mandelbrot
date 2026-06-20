; ============================================================
;  mandelbrot.asm
;  ASCII-art Mandelbrot set renderer — pure x86-64 assembly.
;
;  No libc, no dependencies — talks directly to the Linux kernel
;  via raw syscalls (write, exit). Uses SSE2 double-precision
;  floats for the complex-plane math.
;
;  Build :  nasm -f elf64 mandelbrot.asm -o mandelbrot.o
;           ld mandelbrot.o -o mandelbrot
;  Run   :  ./mandelbrot
; ============================================================

global _start

%define COLS      80
%define ROWS      40
%define MAXITER   50
%define NCHARS    9        ; index range 0..9 (10 chars)

section .data
    chars       db " .:-=+*#%@"   ; escape-speed gradient, dim -> dense
    xmin        dq -2.5
    xmax        dq  1.0
    ymin        dq -1.0
    ymax        dq  1.0
    four        dq  4.0
    two         dq  2.0
    cols_const  dd  COLS
    rows_const  dd  ROWS

section .bss
    dx_step     resq 1
    dy_step     resq 1
    cx_val      resq 1
    cy_val      resq 1
    linebuf     resb COLS + 1      ; +1 for trailing newline

section .text
_start:
    ; dx = (xmax - xmin) / COLS
    movsd    xmm0, [xmax]
    subsd    xmm0, [xmin]
    cvtsi2sd xmm1, dword [cols_const]
    divsd    xmm0, xmm1
    movsd    [dx_step], xmm0

    ; dy = (ymax - ymin) / ROWS
    movsd    xmm0, [ymax]
    subsd    xmm0, [ymin]
    cvtsi2sd xmm1, dword [rows_const]
    divsd    xmm0, xmm1
    movsd    [dy_step], xmm0

    xor      r12, r12          ; r12 = row index (y)

row_loop:
    cmp      r12, ROWS
    jge      finished

    ; cy = ymin + r12 * dy
    cvtsi2sd xmm2, r12
    movsd    xmm0, [dy_step]
    mulsd    xmm0, xmm2
    addsd    xmm0, [ymin]
    movsd    [cy_val], xmm0

    xor      r13, r13          ; r13 = col index (x)

col_loop:
    cmp      r13, COLS
    jge      row_done

    ; cx = xmin + r13 * dx
    cvtsi2sd xmm2, r13
    movsd    xmm0, [dx_step]
    mulsd    xmm0, xmm2
    addsd    xmm0, [xmin]
    movsd    [cx_val], xmm0

    pxor     xmm3, xmm3        ; zx = 0.0
    pxor     xmm4, xmm4        ; zy = 0.0
    xor      r14, r14          ; iteration counter

iter_loop:
    cmp      r14, MAXITER
    jge      iter_done

    movsd    xmm5, xmm3
    mulsd    xmm5, xmm3        ; zx2 = zx*zx
    movsd    xmm6, xmm4
    mulsd    xmm6, xmm4        ; zy2 = zy*zy

    movsd    xmm7, xmm5
    addsd    xmm7, xmm6
    comisd   xmm7, [four]
    ja       iter_done         ; |z|^2 > 4 -> escaped

    ; new_zy = 2*zx*zy + cy
    movsd    xmm0, xmm3
    mulsd    xmm0, xmm4
    mulsd    xmm0, [two]
    addsd    xmm0, [cy_val]

    ; new_zx = zx2 - zy2 + cx
    movsd    xmm1, xmm5
    subsd    xmm1, xmm6
    addsd    xmm1, [cx_val]

    movsd    xmm3, xmm1        ; zx = new_zx
    movsd    xmm4, xmm0        ; zy = new_zy

    inc      r14
    jmp      iter_loop

iter_done:
    ; char index = iter * NCHARS / MAXITER  (0 = escaped fast, 9 = never escaped)
    mov      rax, r14
    imul     rax, NCHARS
    mov      rcx, MAXITER
    xor      rdx, rdx
    div      rcx

    lea      rsi, [chars]
    movzx    rbx, byte [rsi + rax]
    mov      [linebuf + r13], bl

    inc      r13
    jmp      col_loop

row_done:
    mov      byte [linebuf + COLS], 10   ; '\n'

    mov      rax, 1              ; sys_write
    mov      rdi, 1              ; stdout
    lea      rsi, [linebuf]
    mov      rdx, COLS + 1
    syscall

    inc      r12
    jmp      row_loop

finished:
    mov      rax, 60             ; sys_exit
    xor      rdi, rdi
    syscall
