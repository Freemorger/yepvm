const std   = @import("std");
const vm    = @import("../vm.zig");
const stack = @import("../stack.zig");
const vals  = @import("../stack.zig");


// helper func that collects flags, calcs tgt addr 
// and returns it  
// also goes back to original addr after calc
fn jmphandler(self: *vm.VM) !usize {
    const original_ip = self.ip;
    const flags = self.program.items[self.ip + 1];
    self.ip += 2;
    
    const col_addr_slot = try self.collect_type(u64);
    const col_addr = col_addr_slot.val.Uint;
    var tgt_addr: u64 = undefined;

    // is rel jump 
    if ((flags & 1) == 1) {
        // is minus (go back)
        var minus = false;
        if ((flags & (1 << 1)) == 1) {
            minus = true; 
        }

        if (minus) {
            tgt_addr = original_ip - col_addr;
        } else {
            tgt_addr = original_ip + col_addr;
        }
    } else {
        tgt_addr = col_addr;
    }

    self.ip -= 2; // returning back to og 
    return tgt_addr;
}

/// `jmp` - uncoditional jump to addr 
/// 0x30, size: 10 
/// Args: flags (1b), addr (8b)
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel 
pub fn op_jmp(self: *vm.VM) !void {
    self.ip = try jmphandler(self);
}

/// `jz`/`je` - jump if equal (zero flag set to 0)
/// 0x31, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jz(self: *vm.VM) !void {
    if ((self.flags & vm.VmFlags.Zero.getBit()) != 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}

/// `jnz`/`jne` - jump if not equal (zero flag isnt set)
/// 0x32, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jnz(self: *vm.VM) !void {
    if ((self.flags & vm.VmFlags.Zero.getBit()) == 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}

/// `jl` - jump if less (negative flag is set)
/// 0x33, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jl(self: *vm.VM) !void {
    const fbit = vm.VmFlags.Negative.getBit();
    if ((self.flags & fbit) != 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}

/// `jl` - jump if greater (negative and zero flags not set)
/// 0x34, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jg(self: *vm.VM) !void {
    const bit_z = vm.VmFlags.Zero.getBit();
    const bit_n = vm.VmFlags.Negative.getBit();
    
    if ((self.flags & (bit_z | bit_n)) == 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}

/// `jge` - jump if greater or equal (negative flag not set)
/// 0x35, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jge(self: *vm.VM) !void {
    const bit_n = vm.VmFlags.Negative.getBit();
    
    if ((self.flags & bit_n) == 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}

/// `jle` - jump if less or equal (negative or zero flag set)
/// 0x36, size: 10 
/// Args: flags (1b), addr (8b) 
/// Flags: last bit for rel/absolute addr, 
/// prelast for minus if rel
pub fn op_jle(self: *vm.VM) !void {
    const bit_z = vm.VmFlags.Zero.getBit();
    const bit_n = vm.VmFlags.Negative.getBit();
    
    if ((self.flags & (bit_z | bit_n)) != 0) {
        self.ip = try jmphandler(self);
    } else {
        self.ip += 10;
    }
}
