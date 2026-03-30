const std = @import("std");
const yepvm = @import("vm.zig");

pub fn main() !void {
    var args = std.process.args();
    
    _ = args.skip(); 
    
    const first_arg = args.next() orelse {
        std.debug.print("Error: Missing argument\n", .{});
        return;
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();

    const filename = try gpa_alloc.dupe(u8, first_arg);
    defer gpa_alloc.free(filename);

    var vm = try yepvm.VM.init(gpa_alloc);
    try vm.load_file(filename, gpa_alloc);
    try vm.run();
}
