const std = @import("std");
const mem = std.mem;

const nerd_url: []const u8 = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/";

pub fn install_nerd(allocator: mem.Allocator, name: []const u8) !void {
    const url = try std.fmt.allocPrint(allocator, "{s}{s}.zip", .{ nerd_url, name });
    _ = url;
}
pub fn install_zip(allocator: mem.Allocator, path: []const u8) !void {
    _ = path;
    _ = allocator;
}
pub fn install_url(allocator: mem.Allocator, url: []const u8) !void {
    _ = url;
    _ = allocator;
}

fn download(gpa: mem.Allocator, url: []const u8) ![]const u8 {
    // TODO: Validate why zig's http client is not working properly
    // downloading zip files, and replace the `wget` process once is fixed

    var cp = std.ChildProcess.init(&[_][]const u8{ "wget", url }, gpa);
    const term = try cp.spawnAndWait();
    _ = term;
}
