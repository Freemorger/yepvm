const std    = @import("std");
const stack  = @import("stack.zig");
const vmvals = @import("values.zig");
const vmmath = @import("instrs/maths.zig");

pub const VmError = error {
    IllegalInstruction,
    UnexpectedEOF,
    UnexpectedEOS, // end of stack
    UnexpectedType,
    UnexpectedVmType,
    TypeMismatch,
    UnknownCast,
};

pub const VM = struct {
    ip: usize, // instruction pointer 
    running: bool,

    program: std.ArrayList(u8),
    stack: std.ArrayList(stack.StackSlot),
    call_stack: std.ArrayList(stack.StackFrame),
    heap: std.ArrayList(u8),
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) !VM {
        return VM {
            .ip = 0,
            .running = true,
            .program = try std.ArrayList(u8)
                .initCapacity(alloc, 4096),
            .stack = try std.ArrayList(stack.StackSlot)
                .initCapacity(alloc, 1024),
            .call_stack = try std.ArrayList(stack.StackFrame)
                .initCapacity(alloc, 256),
            .heap = try std.ArrayList(u8)
                .initCapacity(alloc, 4096),
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *VM) void {
        self.program.deinit(self.alloc);
        self.stack.deinit(self.alloc);
        self.call_stack.deinit(self.alloc);
        self.heap.deinit(self.alloc);
    }

    /// Loads program from file 
    pub fn load_file(self: *VM, path: []const u8, alloc: std.mem.Allocator) !void {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buffer: [4096]u8 = undefined;
        var reader = file.reader(&buffer);
        const filesize = try reader.getSize();

        try self.program.ensureUnusedCapacity(alloc, filesize);
        const writebuf = self.program.unusedCapacitySlice();

        _ = try reader.interface.readSliceShort(writebuf);
        self.program.items.len += filesize;
    }

    pub fn run(self: *VM) !void {
        while (self.ip < self.program.items.len and self.running) {
            const opcode = self.program.items[self.ip];
            // std.debug.print("{}\n", .{opcode});
            try OPERATIONS[opcode](self);
        } 
    }

    /// `halt` instr handler which gracefully ends vm work 
    /// Opcode: 0xFF
    /// No arguments.
    pub fn op_halt(self: *VM) !void {
        self.running = false;
    }

    /// `print` dbg print last val from stack by poping it 
    /// Opcode: 0x1 
    /// No args 
    pub fn op_print(self: *VM) !void {
        var slot = self.stack.pop() orelse return VmError.UnexpectedEOS;
        defer slot.deinit(self.alloc);
        switch (slot.val) {
            vmvals.VmType.Uint => |u| {
                std.debug.print("{}\n", .{u});
            },
            vmvals.VmType.Int => |i| {
                std.debug.print("{}\n", .{i});
            },
            vmvals.VmType.Float => |f| {
                std.debug.print("{}\n", .{f});
            },
            vmvals.VmType.Str => |s| {
                std.debug.print("{s}", .{s.str});
            },
        }
        self.ip += 1;
    } 

    pub fn unimplemented(self: *VM) !void {
        _ = self;
        return VmError.IllegalInstruction; 
    }

    /// Collects value of type T from self.program[self.ip]
    /// Doesnt change self.ip! caller must add sizeof T by themselves
    pub fn collect_type(self: *VM, comptime T: type) !stack.StackSlot {
        const typesize = @sizeOf(T);
        var buf: [8]u8 = undefined;
        @memcpy(
            &buf,
            self.program.items[self.ip..self.ip + typesize]
        );
        const val = try val_from_le_bytes(T, &buf);

        const vmv = switch (T) {
            usize, u64, u32 => vmvals.VmValue {
                .Uint = val
            },
            isize, i64, i32 => vmvals.VmValue {
                .Int = val
            },
            f64 => vmvals.VmValue {
                .Float = val 
            },
            else => |t| {
                std.debug.print("{}\n", .{t});
                return VmError.UnexpectedType; 
            }
        };
        
        const slot = stack.StackSlot {
            .addr = self.stack.items.len,
            .val = vmv, 
        };

        return slot; 
    } 
};

fn val_from_le_bytes(comptime T: type, bytes: *[@sizeOf(T)]u8) !T {
    switch (@typeInfo(T)) {
        .int => {
            const val = std.mem.readInt(
                T, 
                bytes, 
                .little
            );
            return val;
        },
        .float => {
            const IntType = std.meta.Int(.signed, @bitSizeOf(T));
            const bits = std.mem.readInt(
                IntType,
                bytes,
                .little 
            );
            return @bitCast(bits);
        },
        else => {
            @compileError("Unsupported type " ++ @typeName(T));
        }
    }
}

pub const InstructionHandler = *const fn(*VM) anyerror!void;

pub const OPERATIONS: [256]InstructionHandler = makeOperations();

fn makeOperations() [256]InstructionHandler {
    var handlers: [256]InstructionHandler = undefined;

    for (&handlers) |*h| {
        h.* = VM.unimplemented;
    }

    
    handlers[0xFF] = VM.op_halt;
    handlers[0x01] = VM.op_print;
    
    handlers[0x10] = stack.op_push;
    handlers[0x11] = stack.op_pop;
    handlers[0x12] = stack.op_dupe;
    handlers[0x13] = stack.op_swap;
    handlers[0x14] = stack.op_cast;

    handlers[0x20] = vmmath.op_add;

    
    return handlers;
}
