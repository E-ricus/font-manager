const std = @import("std");

const command = @import("command.zig");
const manager = @import("manager.zig");

const debug = std.debug;
const io = std.io;
const mem = std.mem;
const process = std.process;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    arena_instance.deinit();
    const gpa = arena_instance.allocator();
    // TODO: Capture the especific error, and change message accordingly.
    run(gpa) catch {
        fatal("Something went wrong");
    };
}

fn fatal(msg: []const u8) noreturn {
    std.log.err("Invalid usage\n {s}", .{msg});
    process.exit(1);
}

fn run(gpa: mem.Allocator) !void {
    const cmd = try command.run(gpa);
    switch (cmd.option) {
        .install_nerd => |name| try manager.install_nerd(gpa, name),
        .install_url => |url| try manager.install_url(gpa, url),
        .install_zip => |path| try manager.install_zip(gpa, path),
    }
}
test {
    @import("std").testing.refAllDecls(@This());
}
