const std = @import("std");

const process = std.process;
const io = std.io;
const mem = std.mem;

const help =
    \\ Usage: font-manager [command] [options]
    \\  Commands:
    \\      install [option] [name]      Installs a font.
    \\      uninstall                    Uninstalls the given font if is already installed.
    \\  Install options:
    \\      -n, --nerd [name]            Installs the given font from the nerd aggregator. --nerd option is mutually exclusive with --from-zip and --from-url
    \\      -z, --from-zip [path]        Installs the font contained in the zip located in the given path. --from-zip is mutually exclusive with --nerd and --from-url
    \\      -u, --from-url [url]         Downloads and installs the font with the given url. --from-url is mutually exclusive with --nerd and --from-zip
    \\  General options:
    \\      -h, --help                   Display help information.
;

const invalid =
    \\ Usage: font-manager [command] [options]
    \\ for more info try --help
;

const Command = struct {
    option: Option,
    interactive: bool = false,
    use_otf: bool = false,

    fn setOpt(self: *@This(), opt: []const u8) !void {
        if (mem.eql(u8, opt, "--interactive") or mem.eql(u8, opt, "-i")) {
            self.interactive = true;
            return;
        }
        if (mem.eql(u8, opt, "--use-otf")) {
            self.use_otf = true;
            return;
        }
        return Error.InvalidInstallOption;
    }
};

// TODO: Add more granular errors per case
const Error = error{
    InvalidUsage,
    InvalidInstallOption,
    InvalidInstallCommand,
};

const Option = union(enum) {
    install_nerd: []const u8,
    install_url: []const u8,
    install_zip: []const u8,
    uninstall: []const u8,

    fn formArgs(arg: []const u8, value: []const u8) !@This() {
        if (mem.eql(u8, arg, "--nerd") or mem.eql(u8, arg, "-n"))
            return Option{ .install_nerd = value };
        if (mem.eql(u8, arg, "--from-url") or mem.eql(u8, arg, "-u"))
            return Option{ .install_url = value };
        if (mem.eql(u8, arg, "--from-zip") or mem.eql(u8, arg, "-z"))
            return Option{ .install_zip = value };
        return Error.InvalidInstallCommand;
    }
};

// Used as the public Api to run and allow testing on parse
pub fn run(allocator: mem.Allocator) Command {
    // TODO: switch the error to print different messages for each invalid message.
    var iter = try process.argsWithAllocator(allocator);
    defer iter.deinit();
    const command = parse(iter) catch fatal(invalid);
    return command;
}

fn parse(iter: anytype) !Command {
    var args_iter = iter;
    // ignore executable
    _ = args_iter.skip();
    const len = args_iter.inner.count;
    var sub_command = args_iter.next() orelse return Error.InvalidUsage;
    if (len == 2 and (std.mem.eql(u8, sub_command, "--help") or std.mem.eql(u8, sub_command, "-h")))
        try exit(help);
    if (std.mem.eql(u8, sub_command, "install")) {
        const arg = args_iter.next() orelse return Error.InvalidUsage;
        const value = args_iter.next() orelse return Error.InvalidUsage;
        const option = try Option.formArgs(arg, value);
        var command = Command{ .option = option };
        while (args_iter.next()) |opt| {
            try command.setOpt(opt);
        }
        return command;
    }
    if (std.mem.eql(u8, sub_command, "uninstall")) {
        const path = args_iter.next() orelse return Error.InvalidUsage;
        return Command{ .option = Option{ .uninstall = path } };
    }
    return Error.InvalidUsage;
}

fn exit(msg: []const u8) !void {
    try io.getStdOut().writeAll(msg);
    process.exit(0);
}

fn fatal(msg: []const u8) noreturn {
    std.log.err("Invalid usage\n {s}", .{msg});
    process.exit(1);
}

// For testing
const Inner = struct {
    const Self = @This();
    // argsv: [][:0]u8,
    argsv: [][]const u8 = undefined,
    index: usize = 0,
    count: usize = 0,

    fn set(self: *Self, argsv: [][]const u8) void {
        self.argsv = argsv;
        self.index = 0;
        self.count = argsv.len;
    }

    fn next(self: *Self) ?([]const u8) {
        if (self.index == self.count) return null;

        const s = self.argsv[self.index];
        self.index += 1;
        return s;
    }

    fn skip(self: *Self) bool {
        if (self.index == self.count) return false;

        self.index += 1;
        return true;
    }
};
const Iter = struct {
    inner: Inner,
    fn next(self: *@This()) ?([]const u8) {
        return self.inner.next();
    }
    fn skip(self: *@This()) bool {
        return self.inner.skip();
    }
};

test "parse invalid" {
    var iter = Iter{ .inner = Inner{} };
    var args = [_][]const u8{ "font-manager", "invalid" };
    iter.inner.set(&args);
    try std.testing.expectError(Error.InvalidUsage, parse(iter));
    args = [_][]const u8{ "font-manager", "install" };
    iter.inner.set(&args);
    try std.testing.expectError(Error.InvalidUsage, parse(iter));
    args = [_][]const u8{ "font-manager", "uninstall" };
    iter.inner.set(&args);
    try std.testing.expectError(Error.InvalidUsage, parse(iter));
    var args2 = [_][]const u8{ "font-manager", "install", "-h" };
    iter.inner.set(&args2);
    try std.testing.expectError(Error.InvalidUsage, parse(iter));
    args2 = [_][]const u8{ "font-manager", "install", "-n" };
    iter.inner.set(&args2);
    try std.testing.expectError(Error.InvalidUsage, parse(iter));
}

test "parse command" {
    var iter = Iter{ .inner = Inner{} };
    var args = [_][]const u8{ "font-manager", "install", "-n", "FiraCode" };
    iter.inner.set(&args);
    var command = try parse(iter);
    try std.testing.expect(std.meta.eql(command.option, Option{ .install_nerd = "FiraCode" }));
    args = [_][]const u8{ "font-manager", "install", "-z", "./font.zip" };
    iter.inner.set(&args);
    command = try parse(iter);
    try std.testing.expect(std.meta.eql(command.option, Option{ .install_zip = "./font.zip" }));
    args = [_][]const u8{ "font-manager", "install", "-u", "https://download.zip" };
    iter.inner.set(&args);
    command = try parse(iter);
    try std.testing.expect(std.meta.eql(command.option, Option{ .install_url = "https://download.zip" }));
    var args2 = [_][]const u8{ "font-manager", "uninstall", "FiraCode" };
    iter.inner.set(&args2);
    command = try parse(iter);
    try std.testing.expect(std.meta.eql(command.option, Option{ .uninstall = "FiraCode" }));
}

test "parse invalid install" {
    var iter = Iter{ .inner = Inner{} };
    var args = [_][]const u8{ "font-manager", "install", "-n", "FiraCode", "-a" };
    iter.inner.set(&args);
    try std.testing.expectError(Error.InvalidInstallOption, parse(iter));
}

test "parse install option" {
    var iter = Iter{ .inner = Inner{} };
    var args = [_][]const u8{ "font-manager", "install", "-n", "FiraCode", "-i" };
    iter.inner.set(&args);
    var command = try parse(iter);
    const option = Option{ .install_nerd = "FiraCode" };
    try std.testing.expect(std.meta.eql(command, Command{ .option = option, .interactive = true, .use_otf = false }));
    args = [_][]const u8{ "font-manager", "install", "-n", "FiraCode", "--use-otf" };
    iter.inner.set(&args);
    command = try parse(iter);
    try std.testing.expect(std.meta.eql(command, Command{ .option = option, .interactive = false, .use_otf = true }));
    var args2 = [_][]const u8{ "font-manager", "install", "-n", "FiraCode", "--use-otf", "-i" };
    iter.inner.set(&args2);
    command = try parse(iter);
    try std.testing.expect(std.meta.eql(command, Command{ .option = option, .interactive = true, .use_otf = true }));
}
