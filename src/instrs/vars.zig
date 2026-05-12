const std   = @import("std");
const vm    = @import("../vm.zig");
const vals  = @import("../values.zig");
const stack = @import("../stack.zig");

/// 0x50, size: 2 
/// Args: slot idx 
/// Pop top stack elem and store it as local 
pub fn op_lstore(self: *vm.VM) !void {
    const slot = self.stack.pop() 
        orelse return vm.VmError.UnexpectedEOS;
    const idx = self.program.items[self.ip + 1];

    const frame = &self.call_stack.items[self.csp];
    const def = stack.StackSlot.def(); 

    try insertOrExtend(self.alloc, idx, slot, def, &frame.locals);

    self.ip += 2;
}


fn insertOrExtend(
    alloc: std.mem.Allocator, 
    idx: usize, 
    value: stack.StackSlot, 
    default: stack.StackSlot, 
    list: *std.ArrayList(stack.StackSlot),
) !void {
    const len = list.items.len;

    if (len <= idx) {
        try list.appendNTimes(alloc, default, (idx - len) + 1);
    }

    list.items[idx] = value;
}

