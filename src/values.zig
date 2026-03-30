const std = @import("std");

pub const VmType = enum(u8) {
    Uint = 1,
    Int = 2,
    Float = 3,
    Str = 4,
};

pub const VmStr = struct {
    str: []u8,
    owned: bool,
};

pub const VmValue = union(VmType) {
    Uint: usize,
    Int: isize,
    Float: f64,
    Str: VmStr,
};
