addPrefixedFunction 'pd' 'Debug print'
rust_pd() {
  printf %s\\n 'println!("{:?}", <>);'
}

addPrefixedFunction 'print' 'Print'
rust_print() {
  printf %s\\n 'println!("{}", <>);'
}

addPrefixedFunction 'macro' 'Macro rules'
rust_macro() {
  <<EOF cat -
macro_rules! <> {
    (<>) => {<>};
}
EOF
}
