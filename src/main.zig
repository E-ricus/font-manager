const std = @import("std");

const command = @import("command.zig");

const debug = std.debug;
const io = std.io;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const gpa = arena_instance.allocator();

    _ = try command.run(gpa);

    // var cp = std.ChildProcess.init(&[_][]const u8{ "wget", s }, gpa);
    // const term = try cp.spawnAndWait();
}

test {
    @import("std").testing.refAllDecls(@This());
}
