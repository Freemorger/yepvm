const std   = @import("std");
const vm    = @import("../vm.zig");
const stack = @import("../stack.zig");
const vals  = @import("../values.zig");

/// `add` - performs addition of 2 top popped stack elems
/// Opcode: 0x20, size: 1
/// Args: -
pub fn op_add(self: *vm.VM) !void {
    return binaryOp(self, addImpl);
}

/// `sub` - performs subtraction of 2 top popped stack elems 
/// Opcode: 0x21, size: 1
/// Args: -
pub fn op_sub(self: *vm.VM) !void {
    return binaryOp(self, subImpl);
}

/// `mul` - performs multiplication of 2 top popped stack elems 
/// Opcode: 0x22, size: 1 
/// Args: - 
pub fn op_mul(self: *vm.VM) !void {
    return binaryOp(self, mulImpl);
}

/// `div` - performs division of 2 top popped stack elems 
/// Opcode: 0x23, size: 1 
/// Args: - 
pub fn op_div(self: *vm.VM) !void {
    return binaryOp(self, divImpl);
}

/// `rem` - get remainder of 2 top popped stack elems division 
/// Opcode: 0x24, size: 1 
/// Args: - 
pub fn op_rem(self: *vm.VM) !void {
    return binaryOp(self, remImpl);
}

/// `sqrt` - get square root of 1 top popped stack elem
/// return is float!
/// Opcode: 0x25, size: 1 
/// Args: - 
pub fn op_sqrt(self: *vm.VM) !void {
    return unaryOp(self, sqrtImpl);
}

fn binaryOp(
    self: *vm.VM,
    op: fn (alloc: std.mem.Allocator, a: vals.VmValue, b: vals.VmValue) anyerror!vals.VmValue,
) !void {
    var lhs = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    var rhs = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;

    var t1 = lhs.val.get_type() orelse return vm.VmError.UnexpectedVmType;
    var t2 = rhs.val.get_type() orelse return vm.VmError.UnexpectedVmType;

    if (vals.VmType.to_higher_common(&t1, &t2)) |common| {
        if (t1 != common) lhs.val = try lhs.val.cast(common, self.alloc);
        if (t2 != common) rhs.val = try rhs.val.cast(common, self.alloc);
    }

    const result = try op(self.alloc, lhs.val, rhs.val);

    try self.stack.append(self.alloc, .{
        .addr = self.stack.items.len,
        .val = result,
    });

    self.ip += 1;
}

fn unaryOp(
    self: *vm.VM,
    op: fn (alloc: std.mem.Allocator, a: vals.VmValue) anyerror!vals.VmValue,
) !void {
    const lhs = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;

    const result = try op(self.alloc, lhs.val);

    try self.stack.append(self.alloc, .{
        .addr = self.stack.items.len,
        .val = result,
    });

    self.ip += 1;
}

fn addImpl(
    alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue,
) !vals.VmValue {
    return switch (a) {
        .Uint => |av| switch (b) {
            .Uint => .{ .Uint = av + b.Uint },
            else => error.TypeMismatch,
        },
        .Int => |av| switch (b) {
            .Int => .{ .Int = av + b.Int },
            else => error.TypeMismatch,
        },
        .Float => |av| switch (b) {
            .Float => .{ .Float = av + b.Float },
            else => error.TypeMismatch,
        },
        .Str => |s1| switch (b) {
            .Str => |s2| .{
                .Str = .{
                    .owned = true,
                    .str = try std.fmt.allocPrint(alloc, "{}{}", .{ s1, s2 }),
                },
            },
            else => error.TypeMismatch,
        },
    };
}

fn subImpl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc; 
    return switch (a) {
        .Uint => |uv| switch (b) {
            .Uint => .{ .Uint = uv - b.Uint }, 
            else => error.TypeMismatch
        },
        .Int => |iv| switch (b) {
            .Int => .{ .Int = iv - b.Int },
            else => error.TypeMismatch,
        },
        .Float => |fv| switch (b) {
            .Float => .{ .Float = fv - b.Float },
            else => error.TypeMismatch,
        },
        else => error.UnexpectedVmType,
    };
}

fn mulImpl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    return switch (a) {
        .Uint => |uv| switch (b) {
            .Uint => .{ .Uint = uv * b.Uint }, 
            else => error.TypeMismatch
        },
        .Int => |iv| switch (b) {
            .Int => .{ .Int = iv * b.Int },
            else => error.TypeMismatch,
        },
        .Float => |fv| switch (b) {
            .Float => .{ .Float = fv * b.Float },
            else => error.TypeMismatch,
        },
        .Str => |s1| switch (b) {
            .Uint => |uv| {
                const fin_len = s1.str.len * uv;
                const res_str = try alloc.alloc(u8, fin_len);
                
                for (0..uv) |i| {
                    const dst_idx = i * s1.str.len;
                    const dst = res_str[dst_idx..dst_idx + s1.str.len];
                    @memcpy(dst, s1.str);
                }

                return .{ .Str = vals.VmStr {
                    .owned = true,
                    .str = res_str
                } };
            },
            else => error.TypeMismatch,
        },
        //else => error.TypeMismatch,
    };
}

fn divImpl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv| switch (b) {
            .Uint => .{ .Uint = uv / b.Uint },
            else => error.TypeMismatch
        },
        .Int => |iv| switch (b) {
            .Int => .{ .Int = @divTrunc(iv, b.Int) },
            else => error.TypeMismatch
        },
        .Float => |fv| switch (b) {
            .Float => .{ .Float = fv + b.Float },
            else => error.TypeMismatch
        },
        else => error.UnexpectedVmType,
    };
}

fn remImpl(alloc: std.mem.Allocator,
    a: vals.VmValue,
    b: vals.VmValue) !vals.VmValue {
    _ = alloc;
    return switch (a) {
        .Uint => |uv| switch (b) {
            .Uint => .{ .Uint = uv % b.Uint },
            else => error.TypeMismatch
        },
        .Int => |iv| switch (b) {
            .Int => .{ .Int = @rem(iv, b.Int) },
            else => error.TypeMismatch
        },
        .Float => |fv| switch (b) {
            .Float => .{ .Float = @rem(fv, b.Float) },
            else => error.TypeMismatch
        },
        else => error.UnexpectedVmType,
    };
}

fn sqrtImpl(alloc: std.mem.Allocator, a: vals.VmValue) !vals.VmValue {
    var castedVal = a;
    
    castedVal = try castedVal.cast(vals.VmType.Float, alloc);
    castedVal.Float = @sqrt(castedVal.Float);
    
    return castedVal;
}
