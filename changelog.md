# v0.0.5
- vm flags (zf, nf) 
- jump flags: 0x1 for relative jump, 0x1<<1 for going back in relative jump (minus)

## New instrs

### `jmp` (flags, addr) (0x30, size: 10) - unconditional jump at `addr` with jump flags 

### `jz` (flags, addr) (0x31, size: 10) - jump at `addr` with jump flags `flags`
if zero flag set 

### `jnz` (flags, addr) (0x32, size: 10) - jump at `addr` with jump flags `flags`
if zero flag not set

### `jl` (flags, addr) (0x33, size: 10) - jump at `addr` with jump flags `flags`
if negative flag set

### `jg` (flags, addr) (0x34, size: 10) - jump at `addr` with jump flags `flags`
if neither zero nor negative flags are set

### `jge` (flags, addr) (0x35, size: 10) - jump at `addr` with jump flags `flags`
if negative flag not set

### `jle` (flags, addr) (0x36, size: 10) - jump at `addr` with jump flags `flags`
if zero or negative flag set

### `dmpfl` (-) (0x15, size: 1) - dump flags as uint into stack
