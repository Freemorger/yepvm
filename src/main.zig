const std = @import("std");
const yepvm = @import("vm.zig");

const YEPVM_VERSION = "v0.0.5";

pub fn main() !void {
    var args = std.process.args();
    
    _ = args.skip(); 
    
    const first_arg = args.next() orelse {
        std.debug.print("Error: Missing argument\n", .{});
        return;
    };

    if (std.mem.eql(u8, first_arg, "--version")) {
        std.debug.print("Yepvm {s}\n", .{YEPVM_VERSION});
        return;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const gpa_alloc = gpa.allocator();

    const filename = try gpa_alloc.dupe(u8, first_arg);
    defer gpa_alloc.free(filename);

    var vm = try yepvm.VM.init(gpa_alloc);
    defer vm.deinit();
    try vm.load_file(filename, gpa_alloc);
    try vm.run();
}
