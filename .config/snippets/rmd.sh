addPrefixedFunction 'rmd' 'init_tetra_pdf' 'Tetra Rmd academic thesis'
rmd_init_tetra_pdf() {
  <<EOF cat -
---
title: <>
{# Just show case we can capture variables #}
{\$
  BIB_PATH = env("BIBLIOGRAPHY");
  CSL_PATH = concat env("DOTENVIRONMENT"), "/data/harvard-imperial-college-london.csl";
\$}
bibliography: "{\$ BIB_PATH \$}"
csl: "{\$ CSL_PATH \$}"
output:
  pdf_document:
    number_sections: true
indent:   true
fontsize: 12pt
header-includes:
  - \\usepackage{rotating}                 % Landscape images
  - \\usepackage{setspace}\onehalfspacing  % 1.5 spacing
  - \\pagenumbering{gobble}                % no page numbers for frontmatter
---


\\begin{titlepage}
  \\begin{center}
    \\vspace*{1cm}
    \\Huge
    \\textbf{<title>}

    %\\vspace{0.5cm}
    %\\LARGE
    %Subtitle

    \\vspace{0.5cm}
    \\LARGE
    <name>

    %\\vfill

    \\vspace{0.5cm}
    <supervisor> \\\\
    <uni>

  \\end{center}
\\end{titlepage}

\\newpage
\\pagenumbering{roman}
\\tableofcontents

\\newpage
# Abstract {-}

\\newpage
# Acknowledgement {-}

\\newpage
\\pagenumbering{arabic}
# Introduction {{#section:intro}

\\newpage
# Bibliography {-}

<div id="refs"></div>

\\newpage
# Appendix A {-}

EOF
}

