const std = @import("std");

pub const VmType = enum(u8) {
    Uint = 1,
    Int = 2,
    Float = 3,
};

pub const VmValue = union(VmType) {
    Uint: usize,
    Int: isize,
    Float: f64,
};
