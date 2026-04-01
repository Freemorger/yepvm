const std = @import("std");
const vals = @import("values.zig");
const vm = @import("vm.zig");

pub const StackSlot = struct {
    addr: usize,
    val: vals.VmValue,

    pub fn deinit(self: *StackSlot, alloc: std.mem.Allocator) void {
        switch (self.val) {
            vals.VmType.Str => |s| {
                if (s.owned) {
                    alloc.free(s.str);
                }
            }, 
            else => {}
        }
    }   
};

pub const StackFrame = struct {
    ret_addr: usize,
    bp: usize,
    locals: std.ArrayList(StackSlot),
};

/// `push` - pushes const value on stack 
/// Opcode: 0x10
/// Arg: type (1 byte), value (1..8 b)
pub fn op_push(self: *vm.VM) !void {
    const typeid = self.program.items[self.ip + 1];
    self.ip += 2; // instr and type tag  
    const vmtype = try std.meta.intToEnum(vals.VmType, typeid);

    switch (vmtype) {
        vals.VmType.Uint => {
            const slot = try self.collect_type(usize);
            try self.stack.append(self.alloc, slot);
            self.ip += @sizeOf(usize);
        },
        vals.VmType.Int => {
            const slot = try self.collect_type(isize);
            try self.stack.append(self.alloc, slot);
            self.ip += @sizeOf(isize);
        },
        vals.VmType.Float => {
            const slot = try self.collect_type(f64);
            try self.stack.append(self.alloc, slot);
            self.ip += @sizeOf(f64);
        },
        vals.VmType.Str => {
            const slot = try self.collect_type(u64);
            self.ip += 8; // u64 
            
            switch (slot.val) {
                vals.VmType.Uint => {},
                else => {
                    return vm.VmError.UnexpectedVmType;
                }
            }
            
            const length = slot.val.Uint;

            const slice = self.program.items[self.ip..self.ip + length];
            const res_slot = StackSlot {
                .addr = self.stack.items.len,
                .val = .{ .Str = vals.VmStr {
                        .str = slice,
                        .owned = false,
                    } 
                }
            };
            try self.stack.append(self.alloc, res_slot);
            self.ip += length;
        }
        // else => {
        //     return VmError.UnexpectedVmType;
        // }
    }
}

/// `pop` - pop (remove) the top value from stack 
/// 0x11, size: 1 
/// Args: -
pub fn op_pop(self: *vm.VM) !void {
    var slot = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    defer slot.deinit(self.alloc);

    self.ip += 1;
}

/// `dupe` - duplicate the top value on the stack 
/// 0x12, size: 1 
/// Args: -
pub fn op_dupe(self: *vm.VM) !void {
    const slot = self.stack.getLastOrNull() orelse return vm.VmError.UnexpectedEOS;
    try self.stack.append(self.alloc, slot);
    
    self.ip += 1;
}

/// `swap` - swap top 2 values on stack 
/// 0x13, size: 1 
/// Args: -
pub fn op_swap(self: *vm.VM) !void {
    const slot1 = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    const slot2 = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    
    try self.stack.append(self.alloc, slot1);
    try self.stack.append(self.alloc, slot2);

    self.ip += 1;
}

/// `cast` - performs type cast of top stack frame into specified 
/// 0x14, size: 2 
/// Args: typeid (1 byte)
pub fn op_cast(self: *vm.VM) !void {
    var slot1 = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    
    const typeid = self.program.items[self.ip + 1];
    const vmtype = try std.meta.intToEnum(vals.VmType, typeid);

    slot1.val = try slot1.val.cast(vmtype, self.alloc);
    try self.stack.append(self.alloc, slot1);

    self.ip += 2;
}
