# Mandelbrot ASCII Renderer (x86-64 Assembly)

Render Mandelbrot set jadi ASCII art, ditulis full pakai x86-64 assembly (NASM syntax). Tanpa libc, tanpa dependency — komunikasi langsung ke kernel Linux lewat raw syscall (`write`, `exit`). Matematika bilangan kompleksnya pakai instruksi SSE2 double-precision.

## Preview

```
                                                    ..:...
                                                   ....:...
                                                  ...--%...
                                                 ..-:#@@-:..
                                               .....@@@@@=...
                                            .......=@@@@@=.....
                                           ..:.....:@@@@@:.........
                                         ...+::.@=@@@@@@@@-:=....:.
                                        ....:@@:=@@@@@@@@@@@@:.:::-.
                                       .....+@@@@@@@@@@@@@@@@@@@@-..
                            ....    ......#@@@@@@@@@@@@@@@@@@@@@*:..
                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:...
                            ....    ......#@@@@@@@@@@@@@@@@@@@@@*:..
                                       .....+@@@@@@@@@@@@@@@@@@@@-..
                                        ....:@@:=@@@@@@@@@@@@:.:::-.
                                         ...+::.@=@@@@@@@@-:=....:.
                                               .....@@@@@=...
                                                 ..-:#@@-:..
                                                  ...--%...
                                                   ....:...
```

## Build & Run

Butuh `nasm` dan `ld` (biasanya sudah ada di Linux, atau install via `apt install nasm`).

```bash
nasm -f elf64 mandelbrot.asm -o mandelbrot.o
ld mandelbrot.o -o mandelbrot
./mandelbrot
```

## Cara Kerja

1. Layar dibagi jadi grid 80x40 karakter, dipetakan ke bidang kompleks (real: -2.5 s/d 1.0, imajiner: -1.0 s/d 1.0).
2. Tiap titik `c = cx + cy*i` diiterasi lewat rumus `z = z² + c` sampai 50 kali atau sampai `|z|² > 4` (escape condition).
3. Banyaknya iterasi sebelum "lolos" dipetakan ke salah satu dari 10 karakter gradasi `" .:-=+*#%@"` — makin lama lolos (atau gak pernah lolos = bagian dalam set), makin padat karakternya.
4. Setiap baris ditulis langsung ke stdout pakai syscall `write` (rax=1), tanpa lewat libc sama sekali.
5. Program diakhiri dengan syscall `exit` (rax=60).

