#!/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

show_help() {
  printf %s\\n "${NAME} <cmd> <filepath> [<OPTIONS>]" >&2

  printf %s\\n "" "Valid <OPTIONS> are:" >&2
  # Choose the case statement and print its cases
  sed -n '/case "${a}"$/,/esac$/p' "${0}" \
    | sed -n '2,/\*/ s/).*//p' \
    | awk '{list[NR] = $2} END{ for (i=1;i<NR;++i) print "  " list[i]; }' \
  >&2

  printf %s\\n "" "Valid <cmd> are:" >&2
  sed -n '/^ *case "${1}"/,/esac$/p' "${0}" \
    | sed -n '2,/\*/ s/).*//p' \
    | awk '{list[NR] = $2} END{ for (i=1;i<NR;++i) print "  " list[i]; }' \
  >&2
  exit 1
}

tetra() {
  #tetra-cli "$@"
  p="$( command -v tetra-cli )" || exit "$?"
  p="$( realpath "${p}"; printf a )" || exit "$?"; p="${p%?a}"
  run_from_project_root "${p}" "Cargo.toml" cargo run "$@"
}

ENUM_DEFAULT=0
ENUM_TEMP=1

main() {
  # Dependencies
  OUTPUT="${ENUM_DEFAULT}"

  # Options processing
  args=''; literal='false'
  for a in "$@"; do
    "${literal}" || case "${a}"
      in --)        literal='true'; continue
      ;; -h|--help) show_help
      ;; --test)    unit_testing; exit 0
      ;; --temp)    OUTPUT="${ENUM_TEMP}"

      #;; -*) die FATAL 1 "Invalid option '${a}'. See \`${NAME} -h\` for help"
      ;; *)  args="${args} $( outln "${a}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${a}" | eval_escape )"
  done

  eval "set -- ${args}"

  #run: sh % --test
  LINT='false'
  BUILD='false'
  RUN='false'
  BACKGROUND='false'
  case "${1}"
    in background)  BACKGROUND='true'; BUILD='true'
    ;; build)       BUILD='true'
    ;; run)         RUN='true'
    ;; buildrun)    BUILD='true'; RUN='true'
    ;; lint)        LINT='true'
    ;; *)           show_help
  esac

  file="${2}"
  shift 2
  name="${file##*/}"
  stem="${name%.*}"
  ext="$( printf %s "${name##*.}" | awk '{print tolower($0)}' )"
  target_dir=''
  case "${OUTPUT}"
    in "${ENUM_DEFAULT}") target_dir="$( dirname "${1}"; printf a )"
                          target_dir="${target_dir%?a}"
    ;; "${ENUM_TEMP}")    target_dir="${TMPDIR}"
    ;; *) die DEV 1 "Unreachable"
  esac

  # Run
  "${LINT}" && case "${ext}"
    # https://tex.stackexchange.com/questions/173621/how-to-validate-check-a-biblatex-bib-file
    in bib)   cp "${file}" "${TMPDIR}/${name}"
              biber --tool --validate-datamodel "${TMPDIR}/${name}" \
                | sed "/Invalid field 'publisher' for entrytype 'article'/d"

    ;; go)    revive "${file}"
    ;; py)    ruff check "${file}"
    ;; rs)    cargo clippy
    ;; zig)   zig fmt "${file}"; zig ast-check "${file}"
    ;; sh)    shellcheck "${file}"
    ;; yml)   require "yq-go" && yq-go '.' "${file}"
              require "yq"    && yq    '.' "${file}"
    ;; json)  jq '.' "${file}"
    ;; *)  printf %s\\n "Unsupported filetype for linting file '${file}'" >&2
  esac



  "${BUILD}" && case "${ext}"
    in go)      run_from_root "${file}" "main.go" go build
    ;; java)    run_from_root "${file}" "make.sh" ./make.sh build || exit "$?"
    ;; mjs|js)  node "${file}"
    ;; pl)      perl -T "${file}"
    ;; py)      run_from_root "${file}" "venv" process_python "${fpr_target}"
    ;; rs)      print_do cargo build || exit "$?"
    # TODO: Make this use argv instead of dealing with string escaping
    ;; sass)    sassc "${file}" >"${target_dir}/${stem}.css"
    ;; sh)      sh "${file}"
    ;; ts)      bun build "${file}"
    ;; zig)     zig build
    #;; zig)     run_from_root "${file}" "penzai.nimble" nimble build

    ;; adoc|ad|asc)
      process_adoc "${file}" "${target_dir}/${stem}"
    ;; rmd)
      [ "${file}" != "/tmp/${stem}.rmd" ] || die FATAL 1 "Cannot build temp files"
      tetra parse "${file}" >"/tmp/${stem}.rmd"
      Rscript -e "rmarkdown::render('/tmp/tetra.rmd', output_file='${target_dir}/${stem}')"
    ;; md)      rustdoc "${file}" --output "${target_dir}"
    ;; tex)     tectonic "${file}" --print --outdir "${target_dir}" "$@"
    ;; latex)   process_latex "${file}" "${target_dir}/${stem}"
    ;; *)  printf %s\\n "Unsupported filetype for building file '${file}'" >&2
  esac
  "${BUILD}" && notify.sh "Compiled ${file}"



  new_target="${target_dir}/${stem}"
  "${RUN}" && case "${ext}"
    in go)      run_from_root "${file}" "main.go" go run *.go
    ;; java)    run_from_root "${file}" "make.sh" "run" || exit "$?"
    ;; mjs|js)  npm run "${file}"
    ;; pl)      perl "${file}"
    ;; py)      run_from_root "${file}" "venv" process_python test.py
                run_from_root "${file}" "venv" process_python "${fpr_target}"
    ;; rs)      print_do cargo run
    ;; ts)      bun run "${file}"
    ;; sh)      print_do sh "${file}"
    ;; zig)     zig build run

    ;; html)    setsid falkon --private-browsing --no-extensions --new-window "${file}"
    ;; md|rmd|latex|tex)
      if [ -f "${new_target}.pdf" ]
        then handle.sh gui "${new_target}.pdf"
        else setsid falkon "${new_target}.html"
      fi
    ;; *)  printf %s\\n "Unsupported filetype for running file '${file}'" >&2
  esac
  "${RUN}" && notify.sh "Ran ${file}"
}


process_adoc() {
  imagesdir="$( <"${1}" sed -n '/^:imagesdir:/{s/^:.*: *//p}' )"
  dir="$( realpath "${1}"; printf a )"; dir="${dir%?a}"
  dir="$( dirname "${dir}"; printf a )"; dir="${dir%?a}"
  target="$( realpath "${dir}/${imagesdir}"; printf a )"; target="${target%?a}"
  #bibtex="$( gem list --local | grep '^asciidoctor-bibtex ' )" || exit "$?"
  bibtex=''
  if [ -n "${bibtex}" ]
    then bibtex="--require=asciidoctor-bibtex"
    else bibtex=""
  fi

  # '-a webfonts!' disables <link> to fonts.googleapis.com
  #tetra "${1}" | asciidoctor - --backend html5 --destination-dir "${2%/*}" \
  tetra "${1}" | asciidoctor - --backend html5 \
    ${bibtex} \
    --attribute source-highlighter='pygments' \
    --attribute 'webfonts!' \
    --attribute imagesdir="${target}" \
  >"${2}.html"
  errln "${2}.html"
}


# If we want to compile only the necessary amount of times, see:
# http://vim-latex.sourceforge.net/documentation/latex-suite/compiling-multiple.html
process_latex() {
  if sed 5q "$1" | grep -iq 'xelatex'
    then cmd='pdflatex'
    else cmd='xelatex'
  fi
  dir="${2%/*}"

  # Eat the Stdin
  printf %s\\n '' | "${cmd}" --output-directory="${dir}" "$1"
  [ "${1}" != "${2}" ] && cp "${1}" "${2}"
  if grep -iq 'addbibresource' "${1}"; then
    biber "${2}"
  fi
  printf %s\\n '' | "${cmd}" --output-directory="${dir}" "$1"
  printf %s\\n '' | "${cmd}" --output-directory="${dir}" "$1"
}

################################################################################
process_python() {
  # Assume we are running from project root and always want virtual environments
  . venv/bin/activate || { printf %s\n "Error sourcing venv" >&2; exit 1; }
  python "$@"
}

################################################################################
print_do() {
  printf %s\\n "$*" >&2
  "$@"
}

run_from_root() {
  # $1: start path
  # $2: marker filename
  # $@: command to execute
  find_project_root_store_in_vars "${1}" "${2}" ""
  shift 2
  cd "${fpr_dir}" || die FATAL 1 "Could not change to project root '${fpr_dir}'"
  printf %s\\n "Running \`$*\` from '${fpr_dir}' ..." >&2
  "$@"
}

################################################################################
ut() { # unit test
  if [ "${1}" = "${2}" ]
    then printf %s\\n "pass ${3}" >&2
    else die FATAL 1 "${3}: '${1}' != '${2}'"
  fi
}
unit_testing() {
  t="/a/./b/c/../../"; ut "/a" "$( canonicalise "${t}" )" 1

  ( cd /usr/bin && {
      t="../../../../../../../"
      ut "/" "$( canonicalise "${t}" )" 2
    }
  )

  ( dotfiles="$( run_from_project_root "$0" "linker.pl" pwd; printf a )" \
      || { printf %s\\n "Could not find linker.pl" >&2; exit 1; }
    dotfiles="${dotfiles%?a}"
    ut "${HOME}/dotfiles" "${dotfiles}" 3
  )
}

################################################################################

# Helpers
# With only posix sh (so no 'realpath'), turn ${1} into a canonical path
# That means absolute path with no '.' nor '..'
canonicalise() {
  # Turn ${1} into an absolute_path
  if [ -z "${1}" ]; then
    return 1
  elif [ "${1#/}" != "${1}" ]; then  # absolute path
    absolute_path="${1}"
  else  # relative path
    # `printf a` to protect against shellscript's newline trimming
    absolute_path="$( pwd -P; printf a )"; absolute_path="${absolute_path%?a}"
    absolute_path="${absolute_path}/${1}"
  fi

  # Process '..' and '.'
  printf %s\\n "${absolute_path}" \
    | awk -v FS='/' -v RS='' '{
      for (i = 1; i <= NF; ++i) {
        if ($(i) == ".") {
          $(i) = "";
        } else if ($(i) == "..") {
          $(i) = "";
          for (j = i - 1; j >= 1; --j) {
            if ($(j) != "") {
              $(j) = "";
              break;
            }
          }
        }
      }

      for (i = 1; i <= NF; ++i) {
        if ($(i) != "") {
          did_print = 1;
          printf "/%s", $(i);
        }
      }
      if (!did_print) {
        printf "/";
      }
    }'
}

# Check each directory, starting from ${1}, recursively moving up into its
# parents until the file ${2} is found
find_project_root_store_in_vars() {
  # $1: start path
  # $2: is the filename or directory name that exists in the project root dir
  #     and signals we have reached the project dir
  # $3: a path from the current dir that we are prepending directories to until
  #     we reach the project dir, resulting in a path to the same target but
  #     relative to the project dir
  fpr_dir="$( dirname "${1}"; printf a )"; fpr_dir="${fpr_dir%?a}"
  [ "${2#*/}" != "${2}" ] && die DEV 1 "Not a path, just a filename."
  fpr_target="${3}"

  # `printf a` to protect against shellscript's newline trimming
  fpr_dir="$( canonicalise "${fpr_dir}"; printf a )"; fpr_dir="${fpr_dir%a}"
  while [ -n "${fpr_dir}" ]; do
    if [ -e "${fpr_dir}/${2}" ]; then
      return 0
    else
      [ "${fpr_dir}" != "${fpr_dir##*/}" ] \
        || die FATAL 1 "Could not find project marked by '${2}'"
        # We reached `${fpr_dir} = ""` so die
      fpr_target="${fpr_dir##*/}/${fpr_target}"
      fpr_dir="${fpr_dir%/*}"
    fi
  done
  return 1
}

errln() { printf %s\\n "$@" >&2; }
outln() { printf %s\\n "$@"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
require() {
  for dir in $( printf %s "${PATH}" | tr ':' '\n' ); do
    [ -f "${dir}/${1}" ] && [ -x "${dir}/${1}" ] && return 0
  done
  return 1
}

<&0 main "$@"
