const std = @import("std");
const yepvm = @import("vm.zig");

const YEPVM_VERSION = "v0.0.8";

pub fn main(init: std.process.Init) !void {
    var args      = init.minimal.args;
    var args_iter = args.iterate();

    _ = args_iter.skip(); 
    
    const first_arg = args_iter.next() orelse {
        std.debug.print("Error: Missing argument\n", .{});
        return;
    };

    if (std.mem.eql(u8, first_arg, "--version")) {
        std.debug.print("Yepvm {s}\n", .{YEPVM_VERSION});
        return;
    }

    var gpa = std.heap.DebugAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const gpa_alloc = gpa.allocator();

    const filename = try gpa_alloc.dupe(u8, first_arg);
    defer gpa_alloc.free(filename);

    var io_backend = std.Io.Threaded.init(gpa_alloc, .{});
    const io       = io_backend.io();

    var vm = try yepvm.VM.init(gpa_alloc, io);
    defer vm.deinit();
    try vm.load_file(filename, gpa_alloc);
    try vm.run();
}
