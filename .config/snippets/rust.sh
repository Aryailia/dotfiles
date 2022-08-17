addPrefixedFunction 'rust' 'pd' 'Debug print'
rust_pd() {
  printf %s 'println!("{:?}", <>);'
}

addPrefixedFunction 'rust' 'test' 'cmdline test for integrating with vim'
rust_test() {
  printf %s '//run: cargo test -- --nocapture'
}

addPrefixedFunction 'rust' 'init' 'enable compiler warnings'
rust_init() {
  <<EOF cat -
#![warn(
    missing_docs,
    rust_2018_idioms,
    missing_debug_implementations,
    broken_intra_doc_links,
)]
EOF
}

addPrefixedFunction 'rust' 'push_str_format' 'Include for the push_str(format!()) null pattern'
rust_push_str_format() {
  printf %s 'use std::fmt::Write as _;'
}

addPrefixedFunction 'rust' 'print' 'Print'
rust_print() {
  printf %s 'println!("{}", <>);'
}

addPrefixedFunction 'rust' 'dd' '#[derive(Debug)]'
rust_dd() {
  printf %s '#[derive(Debug)]'
}

addPrefixedFunction 'rust' 'macro' 'Macro rules'
rust_macro() {
  <<EOF cat -
macro_rules! <> {
    (<>) => {<>};
}
EOF
}

addPrefixedFunction 'rust' 'iter' 'impl Iterator'
rust_iter() {
  <<EOF cat -
impl<> Iterator for <> {
    type Item = <>;
    fn next(&mut self) -> Option<Self::Item> {
        None
    }
}
EOF
}

addPrefixedFunction 'rust' 'struct' 'struct'
rust_struct() {
  <<EOF cat -
struct <> {
    <>
}

impl <> {
    fn new() -> Self {
        Self {
        }
    }
}
EOF
}

addPrefixedFunction 'rust' 'cargodir' 'CARGO_MANIFEST_DIR'
rust_cargodir() {
  printf %s 'env!("CARGO_MANIFEST_DIR")'
}

addPrefixedFunction 'rust' 'enumid' 'enum to its repr'
rust_enumid() {
  <<EOF cat -
#[repr(usize)]
enum <> {
}
impl <> {
    pub const fn id(&self) -> usize {
        unsafe { *(self as *const Self as *const usize) }
    }
}
EOF
}


addPrefixedFunction 'rust' 'command' 'Basic external command caller'
rust_command() {
  <<EOF cat -
fn pipe(input: &str, cmd: &str, args: &[&str]) -> String {
    use std::io::Write;
    use std::process::{Command, Stdio};
    let child = Command::new(cmd)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .args(args)
        .spawn()
        .expect(cmd);
    write!(child.stdin.as_ref().unwrap(), "{}", input)
        .expect("Could not write to STIDN");
    let output = child.wait_with_output().expect("jq failed to run");
    if !output.status.success() {
        panic!(
            "{}\\n=== STDIN ===\\n{}",
            std::str::from_utf8(&output.stderr).expect("Did not return utf8 error"),
            input,
        );
    }
    String::from_utf8(output.stdout).unwrap()
}
EOF
}
