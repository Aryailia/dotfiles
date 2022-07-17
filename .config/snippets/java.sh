addPrefixedFunction 'java' 'main' 'Main'
java_main() {
  <<EOF cat -
public class <> {
  public static void main(String[] args) {
  }
}
EOF
}

addPrefixedFunction 'java' 'out' 'Print STDOUT'
java_out() {
  printf %s 'System.out.println("'
}

#addPrefixedFunction 'init' 'enable compiler warnings'
#rust_init() {
#  <<EOF cat -
##![warn(
#    missing_docs,
#    rust_2018_idioms,
#    missing_debug_implementations,
#    broken_intra_doc_links,
#)]
#EOF
#}

