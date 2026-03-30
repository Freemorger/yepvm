const std = @import("std");
const vals = @import("values.zig");

pub const StackSlot = struct {
    addr: usize,
    val: vals.VmValue,
};

pub const StackFrame = struct {
    ret_addr: usize,
    bp: usize,
    locals: std.ArrayList(StackSlot),
};
