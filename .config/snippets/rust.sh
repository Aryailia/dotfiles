addPrefixedFunction 'pd' 'Debug print'
rust_pd() {
  printf %s 'println!("{:?}", <>);'
}

addPrefixedFunction 'test' 'cmdline test for integrating with vim'
rust_test() {
  printf %s '//run: cargo test -- --nocapture'
}

addPrefixedFunction 'init' 'enable compiler warnings'
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

addPrefixedFunction 'print' 'Print'
rust_print() {
  printf %s 'println!("{}", <>);'
}

addPrefixedFunction 'dd' '#[derive(Debug)]'
rust_dd() {
  printf %s '#[derive(Debug)]'
}

addPrefixedFunction 'macro' 'Macro rules'
rust_macro() {
  <<EOF cat -
macro_rules! <> {
    (<>) => {<>};
}
EOF
}

addPrefixedFunction 'iter' 'impl Iterator'
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

addPrefixedFunction 'struct' 'struct'
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

addPrefixedFunction 'cargodir' 'CARGO_MANIFEST_DIR'
rust_cargodir() {
  printf %s 'env!("CARGO_MANIFEST_DIR")'
}

addPrefixedFunction 'enumid' 'enum to its repr'
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
