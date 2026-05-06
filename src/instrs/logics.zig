const std   = @import("std");
const vm    = @import("../vm.zig");
const vals  = @import("../values.zig");
const stack = @import("../stack.zig");
const maths = @import("maths.zig");

/// `or` - performs bitwise OR of 2 top popped stack elems 
/// Opcode: 0x40, size: 1
/// Args: - 
pub fn op_or(self: *vm.VM) !void {
    return maths.binaryOp(self, or_impl);
}

fn or_impl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| switch (b) {
            .Uint => |uv2| .{ .Uint = uv1 | uv2 },
            else => vm.VmError.TypeMismatch
        },
        .Int => |iv1| switch (b) {
            .Int => |iv2| .{ .Int = iv1 | iv2 },
            else => vm.VmError.TypeMismatch
        },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}

/// 0x41, size: 1 
/// AND, aka bitwise AND 
/// a & b 
pub fn op_and(self: *vm.VM) !void {
    return maths.binaryOp(self, and_impl);
}

fn and_impl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| switch (b) {
            .Uint => |uv2| .{ .Uint = uv1 & uv2 },
            else => vm.VmError.TypeMismatch
        },
        .Int => |iv1| switch (b) {
            .Int => |iv2| .{ .Int = iv1 & iv2 },
            else => vm.VmError.TypeMismatch
        },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}

/// 0x42, size: 1 
/// XOR, aka bitwise XOR / bitwise exclusive OR 
/// a ^ b 
pub fn op_xor(self: *vm.VM) !void {
    return maths.binaryOp(self, xor_impl);
}

fn xor_impl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| switch (b) {
            .Uint => |uv2| .{ .Uint = uv1 ^ uv2 },
            else => vm.VmError.TypeMismatch
        },
        .Int => |iv1| switch (b) {
            .Int => |iv2| .{ .Int = iv1 ^ iv2 },
            else => vm.VmError.TypeMismatch
        },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}

/// 0x43, size: 1 
/// Not, aka bitwise inversion 
/// ~a 
pub fn op_not(self: *vm.VM) !void {
    return maths.unaryOp(self, not_impl);
}

fn not_impl(alloc: std.mem.Allocator,
    a: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| .{ .Uint = ~uv1 },
        .Int => |iv1| .{ .Int = ~iv1 },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}

/// 0x44, size: 1 
/// Lnot, aka logical not 
/// Returns 1 for value that == 0. Otherwise - 1 
pub fn op_lnot(self: *vm.VM) !void {
    return maths.unaryOp(self, lnot_impl);
}

fn lnot_impl(alloc: std.mem.Allocator, a: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv| .{ .Uint = @intFromBool(uv == 0)},
        .Int => |iv| .{ .Int = @intFromBool(iv == 0)},
        .Float => |fv| .{ .Float = @floatFromInt(@intFromBool(fv == 0.0))},
        else => vm.VmError.UnexpectedVmType,
    };
}

/// 0x45, size: 1 
/// Nz aka nonzero
/// Returns 1 for any value that != 0. Otherwise - 0.
pub fn op_nz(self: *vm.VM) !void {
    return maths.unaryOp(self, nz_impl);
}

fn nz_impl(alloc: std.mem.Allocator, a: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv| .{ .Uint = @intFromBool(uv != 0)},
        .Int => |iv| .{ .Int = @intFromBool(iv != 0)},
        .Float => |fv| .{ .Float = @floatFromInt(@intFromBool(fv != 0.0))},
        else => vm.VmError.UnexpectedVmType,
    };
}

/// 0x46, size: 1 
/// Shl aka bit shift left 
pub fn op_shl(self: *vm.VM) !void {
    return maths.binaryOp(self, shl_impl);
}

fn shl_impl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| switch (b) {
            .Uint => |uv2| .{ .Uint = uv1 << @intCast(uv2) },
            else => vm.VmError.TypeMismatch
        },
        .Int => |iv1| switch (b) {
            .Int => |iv2| .{ .Int = iv1 << @intCast(iv2) },
            else => vm.VmError.TypeMismatch
        },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}

/// 0x47, size: 1 
/// Shr aka bit shift right 
pub fn op_shr(self: *vm.VM) !void {
    return maths.binaryOp(self, shr_impl);
}

fn shr_impl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv1| switch (b) {
            .Uint => |uv2| .{ .Uint = uv1 >> @intCast(uv2) },
            else => vm.VmError.TypeMismatch
        },
        .Int => |iv1| switch (b) {
            .Int => |iv2| .{ .Int = iv1 >> @intCast(iv2) },
            else => vm.VmError.TypeMismatch
        },
        .Float => vm.VmError.FloatBitOp,
        else => vm.VmError.UnexpectedVmType, 
    };
}
