addPrefixedFunction 'zig' 'pd' 'Debug print'
zig_pd() {
  printf %s 'std.debug.print("{}", .{<>});'
}

addPrefixedFunction 'zig' 'init' 'Init'
zig_init() {
  printf %s\\n \
    '//run: zig build -freference-trace test' \
    'const std = @import("std");' \
  # end
}

addPrefixedFunction 'zig' 'main' 'An empty main'
zig_main() {
<<EOF cat -

//run: zig run -freference-trace %

fn main() {
    std.debug.print("{s}\n", .{"Hello, sailor!"});
}

test "test" {

}
EOF
}
