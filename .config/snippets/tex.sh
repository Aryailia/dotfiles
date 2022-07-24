yaml() {
  command -v "yq-go" 2>/dev/null && yq-go "$@" && return 0
  command -v "yq" 2>/dev/null    && yq "$@" && return 0
  exit 1
}

addPrefixedFunction 'tex' 'init_doc' 'For school work'
tex_init_doc() {
  <<EOF cat -
\\documentclass[10.5pt,twoside,a4paper]{article}
\\usepackage{xeCJK}
\\setmainfont{Noto Serif CJK SC}
\\setCJKmainfont{Noto Serif CJK SC}

\\usepackage[margin=2.5cm]{geometry}
\\setlength{\\parindent}{2em}  % Formal CJ[K?] indented by two full-widths

\\author{$( <"${DOTENVIRONMENT}/name.yml" yq-go '.name_s' )}
\\title{<>}
\\date{
  $( <"${DOTENVIRONMENT}/name.yml" yq-go '.year_s' ) \\\\
  <subject> \\\\
  %\\today
}

\\begin{document}

\\makeatletter  % enable use of \\@ commands
\\begin{flushright}      \\@author \\\\ \@date  \\end{flushright}
\\begin{center}\\LARGE{}  \\@title \\\\ [3em]    \\end{center}  % 3+1 newlines
\\makeatother   % back to default

START

\\end{document}
EOF
}

