const std = @import("std");
const stack = @import("stack.zig");
const vmvals = @import("values.zig");

const VmError = error {
    IllegalInstruction,
    UnexpectedEOF,
    UnexpectedType,
    UnexpectedVmType,
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
        const slot = self.stack.pop() orelse return VmError.UnexpectedEOF;
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
        }
        self.ip += 1;
    }

    /// `push` - pushes const value on stack 
    /// Opcode: 0x10
    /// Arg: type (1 byte), value (1..8 b)
    pub fn op_push(self: *VM) !void {
        const typeid = self.program.items[self.ip + 1];
        self.ip += 2; // instr and type tag  
        const vmtype = try std.meta.intToEnum(vmvals.VmType, typeid);

        switch (vmtype) {
            vmvals.VmType.Uint => {
                const slot = try self.collect_type(usize);
                try self.stack.append(self.alloc, slot);
                self.ip += @sizeOf(usize);
            },
            vmvals.VmType.Int => {
                const slot = try self.collect_type(isize);
                try self.stack.append(self.alloc, slot);
                self.ip += @sizeOf(isize);
            },
            vmvals.VmType.Float => {
                const slot = try self.collect_type(f64);
                try self.stack.append(self.alloc, slot);
                self.ip += @sizeOf(f64);
            },
            // else => {
            //     return VmError.UnexpectedVmType;
            // }
        }
    }

    pub fn unimplemented(self: *VM) !void {
        _ = self;
        return VmError.IllegalInstruction; 
    }

    /// Collects value of type T from self.program[self.ip]
    /// Doesnt change self.ip! caller must add sizeof T by themselves
    fn collect_type(self: *VM, comptime T: type) !stack.StackSlot {
        const typesize = @sizeOf(T);
        var buf: [8]u8 = undefined;
        @memcpy(
            &buf,
            self.program.items[self.ip..self.ip + typesize]
        );
        const val = try val_from_be_bytes(T, &buf);

        const vmv = switch (T) {
            usize => vmvals.VmValue {
                .Uint = val
            },
            isize => vmvals.VmValue {
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

    fn val_from_be_bytes(comptime T: type, bytes: *[@sizeOf(T)]u8) !T {
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
};

pub const InstructionHandler = *const fn(*VM) anyerror!void;

pub const OPERATIONS: [256]InstructionHandler = makeOperations();

fn makeOperations() [256]InstructionHandler {
    var handlers: [256]InstructionHandler = undefined;

    for (&handlers) |*h| {
        h.* = VM.unimplemented;
    }

    handlers[0xFF] = VM.op_halt;
    handlers[0x01] = VM.op_print;
    handlers[0x10] = VM.op_push;


    return handlers;
}
