addPrefixedFunction 'pd' 'Debug print'
rust_pd() {
  printf %s 'println!("{:?}", <>);'
}

addPrefixedFunction 'print' 'Print'
rust_print() {
  printf %s 'println!("{}", <>);'
}

addPrefixedFunction 'dd' '#[derive(Debug)]'
rust_dd() {
  printf %s\\n '#[derive(Debug)]'
}

addPrefixedFunction 'macro' 'Macro rules'
rust_macro() {
  <<EOF cat -
macro_rules! <> {
    (<>) => {<>};
}
EOF
}
