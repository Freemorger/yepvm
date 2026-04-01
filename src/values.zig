const std = @import("std");
const vm  = @import("vm.zig");

pub const VmType = enum(u8) {
    Uint  = 1,
    Int   = 2,
    Float = 3,
    Str   = 4,

    pub fn to_higher_common(self: *VmType, other: *VmType) ?VmType {
        const intval1 = @intFromEnum(self.*);
        const intval2 = @intFromEnum(other.*);

        if (!(self.is_numerical() and other.is_numerical())) {
            return null;
        } 

        if (intval1 > intval2) {
            return self.*;
        } else {
            return other.*;
        }
    }

    pub fn is_numerical(self: *VmType) bool {
        switch (self.*) {
            VmType.Uint  => {return true;},
            VmType.Int   => {return true;},
            VmType.Float => {return true;},
            else => {return false;},
        }
    }
};

pub const VmStr = struct {
    str: []u8,
    owned: bool, // whether string is owned by this obj 
};

pub const VmValue = union(VmType) {
    Uint: usize,
    Int: isize,
    Float: f64,
    Str: VmStr,

    pub fn get_type(self: *VmValue) ?VmType {
        switch (self.*) {
            VmValue.Uint  => {return VmType.Uint;},
            VmValue.Int   => {return VmType.Int;},
            VmValue.Float => {return VmType.Float;},
            VmValue.Str   => {return VmType.Str;},
        }
        return null;
    }

    pub fn cast(self: *VmValue, target: VmType, alloc: std.mem.Allocator) !VmValue {
        switch (self.*) {
            VmValue.Uint => |u| {
                switch (target) {
                    .Uint => {
                        return self.*;
                    },
                    .Int => {
                        return VmValue {
                            .Int = @intCast(u)  
                        };
                    },
                    .Float => {
                        return VmValue {
                            .Float = @floatFromInt(u)
                        };
                    },
                    .Str => {
                        return self.to_str(alloc); 
                    },
                } 
            },
            VmValue.Int => |i| {
                switch (target) {
                    .Uint => {
                        return VmValue {
                            .Uint = @intCast(i)  
                        };
                    },
                    .Int => {
                        return self.*;
                    },
                    .Float => {
                        return VmValue {
                            .Float = @floatFromInt(i)
                        };
                    },
                    .Str => {
                        return self.to_str(alloc); 
                    },
                }
            },
            VmValue.Float => |f| {
                switch (target) {
                    .Uint => {
                        return VmValue {
                            .Uint = @intFromFloat(f)  
                        };
                    },
                    .Int => {
                        return VmValue {
                            .Uint = @intFromFloat(f)  
                        };
                    },
                    .Float => {
                        return self.*;
                    },
                    .Str => {
                        return self.to_str(alloc); 
                    },
                }
            },
            .Str => |s| {
                switch (target) {
                    .Uint => {
                        return VmValue {
                            .Uint = try std.fmt.parseInt(
                                usize,
                                s.str,
                                0
                            ) 
                        };
                    },
                    .Int => {
                        return VmValue {
                            .Int = try std.fmt.parseInt(
                                isize,
                                s.str,
                                0
                            )
                        };
                    },
                    .Float => {
                        return VmValue {
                            .Float = try std.fmt.parseFloat(
                                f64,
                                s.str
                            )
                        };
                    },
                    .Str => {return self.*;}
                }
            },
        }
        return vm.VmError.UnknownCast;
    }

    pub fn to_str(self: *VmValue, alloc: std.mem.Allocator) !VmValue {
        switch (self.*) {
            .Uint => |u| {
                const strrep = try std.fmt.allocPrint(
                    alloc, 
                    "{}", 
                    .{u}
                );
                return VmValue {
                    .Str = VmStr {
                        .owned = true,
                        .str = strrep
                    }
                };
            },
            .Int => |i| {
                const strrep = try std.fmt.allocPrint(
                    alloc, 
                    "{}", 
                    .{i}
                );
                return VmValue {
                    .Str = VmStr {
                        .owned = true,
                        .str = strrep
                    }
                };
            },
            .Float => |f| {
                const strrep = try std.fmt.allocPrint(
                    alloc, 
                    "{}", 
                    .{f}
                );
                return VmValue {
                    .Str = VmStr {
                        .owned = true,
                        .str = strrep
                    }
                };
            },
            .Str => |_| {
                return self.*; 
            }
        }
    }
};
