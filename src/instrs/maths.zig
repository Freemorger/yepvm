const std   = @import("std");
const vm    = @import("../vm.zig");
const stack = @import("../stack.zig");
const vals  = @import("../values.zig");


/// `add` - performs addition of 2 top popped stack elems
/// Opcode: 0x20, size: 1
/// Args: -
pub fn op_add(self: *vm.VM) !void {
    var slot1 = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;
    var slot2 = self.stack.pop() orelse return vm.VmError.UnexpectedEOS;

    var vmtype1 = slot1.val.get_type() 
        orelse return vm.VmError.UnexpectedVmType;
    var vmtype2 = slot2.val.get_type()
        orelse return vm.VmError.UnexpectedVmType;

    const common_type = vals.VmType.to_higher_common(
        &vmtype1,
        &vmtype2
    );

    if (common_type) |com_type| {
        if (vmtype1 != com_type) {
            slot1.val = try slot1.val.cast(com_type, self.alloc);
        } 
        if (vmtype2 != com_type) {
            slot2.val = try slot2.val.cast(com_type, self.alloc);
        }
    }

    switch (slot1.val) {
        vals.VmType.Uint => |uv1| {
            switch (slot2.val) {
                vals.VmType.Uint => |uv2| {
                    const res = uv1 + uv2;
                    const res_slot = stack.StackSlot {
                        .addr = self.stack.items.len,
                        .val = vals.VmValue {
                            .Uint = res
                        },
                    };
                    try self.stack.append(self.alloc, res_slot);
                },
                else => |vt2| {
                    std.debug.print("Type mismatch! LHS is {} but RHS is {}\n",
                        .{vt2, uv1}); 
                }
            }
        },
        vals.VmType.Int => |iv1| {
            switch (slot2.val) {
                vals.VmType.Int => |iv2| {
                    const res = iv1 + iv2;
                    const res_slot = stack.StackSlot {
                        .addr = self.stack.items.len,
                        .val = vals.VmValue {
                            .Int = res
                        },
                    };
                    try self.stack.append(self.alloc, res_slot);
                },
                else => |vt2| {
                    std.debug.print("Type mismatch! LHS is {} but RHS is {}\n",
                        .{vt2, iv1}); 
                }
            }
        },
        vals.VmType.Float => |fv1| {
            switch (slot2.val) {
                vals.VmType.Float => |fv2| {
                    const res = fv1 + fv2;
                    const res_slot = stack.StackSlot {
                        .addr = self.stack.items.len,
                        .val = vals.VmValue {
                            .Float = res
                        },
                    };
                    try self.stack.append(self.alloc, res_slot);
                },
                else => |vt2| {
                    std.debug.print("Type mismatch! LHS is {} but RHS is {}\n",
                        .{vt2, fv1}); 
                }
            }
        },
        vals.VmType.Str => |s1| {
            switch (slot2.val) {
                vals.VmType.Str => |s2| {
                    const res = try std.fmt.allocPrint(
                        self.alloc, 
                        "{}{}", 
                        .{s1, s2}
                    );
                    const res_slot = stack.StackSlot {
                        .addr = self.stack.items.len,
                        .val = vals.VmValue {
                            .Str = vals.VmStr {
                                .owned = true,
                                .str = res,
                            }
                        },
                    };

                    try self.stack.append(self.alloc, res_slot);
                },
                else => |vt2| {
                    std.debug.print("Type mismatch! LHS is {} but RHS is {}\n",
                        .{vt2, s1}); 
                }
            }
        },
        //else => {}
    }

    self.ip += 1;
}
