const std = @import("std");

const process = std.process;
const io = std.io;
const mem = std.mem;

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
        return Error.InvalidOption;
    }
};

// TODO: Add new errors for fatals with extra info
const Error = error{
    InvalidInstall,
    InvalidOption,
};

const Option = union(enum) {
    install_nerd: []const u8,
    install_url: []const u8,
    install_zip: []const u8,
    uninstall: []const u8,

    fn formArgs(arg: []const u8, value: []const u8) !@This() {
        if (mem.eql(u8, arg, "--nerd") or mem.eql(u8, arg, "-n"))
            return Option{ .install_nerd = value };
        if (mem.eql(u8, arg, "--from-zip") or mem.eql(u8, arg, "-z"))
            return Option{ .install_zip = value };
        if (mem.eql(u8, arg, "--from-zip") or mem.eql(u8, arg, "-z"))
            return Option{ .install_zip = value };
        return Error.InvalidInstall;
    }
};

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

// Used as the public Api to run and allow testing on parse
// TODO: Catch the error when parse is returning better errors and write it to the stdout
pub fn run(allocator: mem.Allocator) !Command {
    const args = try process.argsAlloc(allocator);
    return parse(allocator, args);
}

// TODO: Return errors with info instead of finishing the program for better testing
fn parse(allocator: std.mem.Allocator, args: []const [:0]u8) !Command {
    defer process.argsFree(allocator, args);
    const len = args.len;
    if (len <= 1)
        fatal(invalid);

    const sub_command = args[1];
    if (len == 2 and (std.mem.eql(u8, sub_command, "--help") or std.mem.eql(u8, sub_command, "-h")))
        try exit(help);
    if (std.mem.eql(u8, sub_command, "install")) {
        if (len < 4)
            fatal(invalid);
        const option = Option.formArgs(args[2], args[3]) catch fatal(invalid);
        var command = Command{ .option = option };
        const options = args[4..];
        for (options) |opt| {
            command.setOpt(opt) catch fatal(invalid);
        }
        return command;
    }
    if (std.mem.eql(u8, sub_command, "uninstall")) {
        if (len != 3)
            fatal(invalid);
        const path = args[2];
        return Command{ .option = Option{ .uninstall = path } };
    }
    fatal(invalid);
}

pub fn fatal(msg: []const u8) noreturn {
    std.log.err("Invalid usage\n {s}", .{msg});
    process.exit(1);
}
pub fn exit(msg: []const u8) !void {
    try io.getStdOut().writeAll(msg);
    process.exit(0);
}

const test_allocator = std.testing.allocator;

// test "test parse invalid" {
//     const args = [1].{"font-manager"};
//     std.testing.expectError(expected_error: anyerror, actual_error_union: anytype)
//     const command = try parse(test_allocator, args);
// }

test "test parse install" {}
test "test parse uninstall" {}
