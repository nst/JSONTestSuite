const std = @import("std");
const allocator = std.testing.allocator;

// /usr/local/zigDir/zig fmt .; /usr/local/zigDir/zig build-exe test_json.zig; ./test_json some_file.json; echo $?
// echo '["Zig 0.8.0-dev.1354+081698156"]' > zig_only.json
// python3 run_tests.py --filter=zig_only.json

pub fn main() void {
    const args = std.process.argsAlloc(allocator) catch |err| {
        std.os.exit(1);
    };

    const file_name = args[1];
    const file = std.fs.cwd().openFile(file_name, .{}) catch |err| {
        std.os.exit(1);
    };
    const reader = file.reader();
    const buf = reader.readAllAlloc(allocator, std.math.maxInt(usize)) catch |err| {
        std.os.exit(1);
    };

    var p = std.json.Parser.init(allocator, false);
    var tree = p.parse(buf) catch |err| {
        std.os.exit(1);
    };

    tree.deinit();
    p.deinit();
    file.close();
    allocator.free(buf);

    std.os.exit(0);
}
