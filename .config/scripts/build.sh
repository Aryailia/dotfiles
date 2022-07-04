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

  #run: sh %
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
  ext="${name##*.}"
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
    in bib)  cp "${file}" "${TMPDIR}/${name}"
             biber --tool --validate-datamodel "${TMPDIR}/${name}" \
               | sed "/Invalid field 'publisher' for entrytype 'article'/d"

    ;; sh)   shellcheck "${file}"
    ;; *)  printf %s\\n "Unsupported filetype for linting file '${file}'" >&2
  esac



  "${BUILD}" && case "${ext}"
    in java)    run_from_project_home "${file}" "make.sh" "build" || exit "$?"
    ;; rs)      print_do cargo build || exit "$?"
    # TODO: Make this use argv instead of dealing with string escaping
    ;; rmd)     Rscript -e "rmarkdown::render('${file}', output_file='${target_dir}/${stem}.pdf')"
    ;; tex)     tectonic "${file}" --print --outdir "${target_dir}" "$@"
    ;; latex)   process_latex "${file}" "${target_dir}/${stem}"
    ;; py)      run_relative_to_project_home "${file}" "requirements.txt" "${file}" python
    ;; *)  printf %s\\n "Unsupported filetype for building file '${file}'" >&2
  esac
  "${BUILD}" && notify.sh "Compiled ${file}"



  "${RUN}" && case "${ext}"
    in java)  run_from_project_home "${file}" "make.sh" "run" || exit "$?"
    ;; rs)    print_do cargo run
    ;; rmd|latex|tex)
              handle.sh gui "${target_dir}/${stem}.pdf"
    ;; py)    run_relative_to_project_home "${file}" "requirements.txt" "${file}" python
    ;; *)  printf %s\\n "Unsupported filetype for running file '${file}'" >&2
  esac
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




print_do() {
  printf %s\\n "$*" >&2
  "$@"
}

cd_project_dir() {
  cdpd_start_dir="$( dirname "${1}"; printf a )"
  cdpd_start_dir="${cdpd_start_dir%?a}"
  cdpd_find_file="${2}"
  cdpd_make="${3}"

  setv_find_project_base "${cdpd_start_dir}" "${cdpd_find_file}" "${cdpd_make}" \
    || die FATAL "$?" "Cannot find project dir for '${cdpd_make}', searching for '${cdpd_find_file}'"
  cdpd_project_dir="${fpb_dir}"
  cdpd_make="${fpb_target}"  # Same file as ${3}, just relative to project_home
  cdpd_make="${cdpd_make#"${cdpd_project_dir}/"}"

  cd "${cdpd_project_dir}" || die FATAL 1 "Cannot cd to project dir '${cdpd_project_dir}'"
}

run_relative_to_project_home() (
  cd_project_dir "${1}" "${2}" "${3}"
  shift 3
  printf %s\\n "Running \`./${cdpd_make} $*\`  from '${cdpd_project_dir}' ..." >&2
  "$@" "./${cdpd_make}"
)

run_from_project_home() (
  cd_project_dir "${1}" "${2}" "${3}"
  shift 2
  printf %s\\n "Running \`./${cdpd_find_file} $*\`  from '${cdpd_project_dir}' ..." >&2
  "./${cdpd_find_file}" "$@"
)


ut() {
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
}




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
setv_find_project_base() {
  fpb_dir="${1}"
  [ "${2#*/}" != "${2}" ] && die DEV 1 "Not a path, just a filename."
  fpb_target="${3}"

  # `printf a` to protect against shellscript's newline trimming
  fpb_dir="$( canonicalise "${fpb_dir}"; printf a )"; fpb_dir="${fpb_dir%a}"
  while [ -n "${fpb_dir}" ]; do
    if [ -e "${fpb_dir}/${2}" ]; then
      return 0
    else
      [ "${fpb_dir}" != "${fpb_dir##*/}" ] || die DEV 1 "Path is not aboslute"
      fpb_target="${fpb_dir##*/}/${fpb_target}"
      fpb_dir="${fpb_dir%/*}"
    fi
  done
  return 1
}

outln() { printf %s\\n "$@"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }

<&1 main "$@"
