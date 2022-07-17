#/bin/sh

NAME="$( basename "${0}"; printf a )"; NAME="${NAME%?a}"

exit_help() {
  <<EOF cat >&2 -
SYNOPSIS
  ${NAME} <COMMAND>

DESCRIPTION
  Neomutt does not have first-tier support for multiple mailboxes (though it is
  possible to configure it, you just have to clear a lot settings when you do).

  This script helps creating an account
  This handles selecting your account which sim

  You typically get notifications that you have new 
EOF

  printf >&2 %s\\n '' 'COMMANDS'
  awk -v FS="" '
    (!start && /^  case "/) { start = 1; }
    (start  && /^    in |^    ;; / && /.*#/) {
      split($0, keyvalue, " *# *");
      len = length(keyvalue[1]) - 7;
      printf("  %s %s\t%s\n",
        substr(keyvalue[1], 8, len - 1),
        keyvalue[2],
        keyvalue[3]);
    }
    (start && /^  esac$/) { start = 0; }
  ' "${0}" | column >&2 -ts '	'

  <<EOF cat - >&2

OPTIONS
  -
    Special argument that says read from STDIN

  --
    Special argument that prevents all following arguments from being
    intepreted as options.
EOF
  exit 1
}

ACCOUNTS_DIR="${XDG_CONFIG_HOME}/neomutt/accounts"
DOMAINS_CSV="${DOTENVIRONMENT}/domains.csv"
MSMTP_CONFIG="${XDG_CONFIG_HOME}/msmtp/config"
MUTT_TOKEN="${DOTENVIRONMENT}/mutt-token.csv"

# Handles options that need arguments
main() {
  # Dependencies

  # Options processing
  args=''
  literal='false'
  for a in "$@"; do
    "${literal}" || case "${a}"
      in --)         literal='true'; continue
      ;; -h|--help)  exit_help

      ;; -*) die FATAL 1 "Invalid option '${a}'. See \`${NAME} -h\` for help"
      ;; *)  args="${args} $( outln "${a}" | eval_escape )"
    esac
    "${literal}" && args="${args} $( outln "${a}" | eval_escape )"
  done

  eval "set -- ${args}"

  # The comments after each case are used in `exit_help()`
  # If it has a comment on the same line as case, then includes in help
  # First comment is for args # Second comment is for description
  case "${1}"
    in ""|login)   #    # FZF menu of which account to log into
      #printf %s\\n "a" "${ACCOUNTS_DIR}"
      config="$( list_null_delimited_files "${ACCOUNTS_DIR}" | fzf --read0 )" \
        || exit "$?"
      exec neomutt -F "${ACCOUNTS_DIR}/${config}"

    ;; add-imap)    #    # Adds an email address only accessed online
      add_muttrc "imap"
      printf >&2 '' "Dont forget to run" "    $NAME add-msmtp"

    ;; add-mailbox) #    # Adds an address stored locally with mailbox format
      die TODO 1 'Not supported yet'

    ;; add-msmtp)   # [<email>]  # Adds the send mail settings
      add_msmtp "${2}"

    ;; add-oauth)   # [<email>]  # Adds the send mail settings
      add_muttrc "oauth"

    # https://github.com/neomutt/neomutt/blob/main/contrib/oauth2/mutt_oauth2.py.README
    ;; dl-oauth2)   #    # Download the semi-official mutt oauth python script
      #url="https://raw.githubusercontent.com/google/gmail-oauth2-tools/master/python/oauth2.py"
      url="https://raw.githubusercontent.com/neomutt/neomutt/main/contrib/oauth2/mutt_oauth2.py"

      curl -L -o "${HOME}/.local/bin/mutt_oauth2.py" "${url}" \
        && chmod 755 -- "${HOME}/.local/bin/mutt_oauth2.py"

    ;; oauth-token) #    # Obtain the token
      mutt_oauth2.py \
        --provider "google" \
        --encryption-pipe 'gpg --encrypt --recipient my-pass' \
        --client-id "$( pass show 'mutt-api-id' )" \
        --client-secret "$( pass show 'mutt-api-secret' )" \
        --authorize "${MUTT_TOKEN}"

    ;; oauth-test) #     # Test the token
      # https://github.com/neomutt/neomutt/issues/3442
      # https://github.com/neomutt/neomutt/blob/main/contrib/oauth2/mutt_oauth2.py.README
      #gtool_oauth2.py --generate_oauth2_token #\

      mutt_oauth2.py \
        --provider "google" \
        --encryption-pipe 'gpg --encrypt --recipient my-pass' \
        --client-id "$( pass show 'mutt-api-id' )" \
        --client-secret "$( pass show 'mutt-api-secret' )" \
        --test "${MUTT_TOKEN}"
      #
    ;; *)  exit_help
  esac
}

#run: sh % add-msmtp
add_muttrc() {
  printf 'Enter name: ' >&2; read -r name || exit "$?"
  printf 'Enter email address: ' >&2; read -r address || exit "$?"

  <<EOF IFS=, read -r _ in_server in_port out_server out_port
$( find_domain_for "${address}" )
EOF

  filename="imap-${address}"
  filepath="${ACCOUNTS_DIR}/${filename}"
  [ -z "${address}" ] && die FATAL 1 "Invalid email address"
  [ -e "${filepath}" ] && die FATAL 1 "Config for '${filepath}' already exists"

  printf >&2 %s\\n "Saving neomuttrc to '${ACCOUNTS_DIR}/${filename}' ..."
  case "${1}"
    in "imap")
      imap_muttrc_template "${name}" "${address}" \
        "${in_server}" "${in_port}" \
        "${out_server}" "${out_port}" \
      >"${filepath}"
    ;; "oauth")
      oauth_muttrc_template "${name}" "${address}" \
        "${in_server}" "${in_port}" \
        "${out_server}" "${out_port}" \
      >"${filepath}"
    ;; *)  die DEV "Invalid argument for add_muttrc '${1}'"
  esac
  exec "${EDITOR}" "${filepath}"
}


add_msmtp() {
  address="${1:-"$(
    printf 'Enter email address: ' >&2; read -r address || exit "$?"
    printf %s "${address}"
  )"}"
  [ -z "${address}" ] && die FATAL 1 "Please enter a non-empty email address"
  server_info="$( find_domain_for "${address}" )" || {
    printf >&2 %s\\n "Cannot find domain info for ${address##*@}"
    printf >&2 %s\\n "Enter manually."
    printf >&2 %s "Press enter to continue... "; read -r _ || exit "$?"
    exec "${EDITOR}" "${MSMTP_CONFIG}"
  }

  <<EOF IFS=, read -r _ in_server in_port out_server out_port
${server_info}
EOF

  if [ -e "${MSMTP_CONFIG}" ]; then
    # print ${MSMTP_CONFIG} with the old entry deleted (if it exists)
    output="$(
    awk -v account="${address}" '
      (/^account   */ && $2 == account) {
        start = 1;
      }
      (!start) { print $0; }
      (start && /^#+/) { start = 0; }
    ' "${MSMTP_CONFIG}" || die FATAL "$?" "Could not delete entry"

    <<EOF cat
account        ${address}
host           ${out_server}
port           ${out_port}
from           ${address}
user           ${address}
passwordeval   "pass show email/${address}"

################################################################################
EOF
    )" || exit "$?"

    printf >&2 %s\\n "Saving msmtp config to '${MSMTP_CONFIG}' ..."
    printf %s\\n "${output}" >"${MSMTP_CONFIG}"

  else
    printf >&2 "Init the MSMTP config file with defaults."
    printf >&2 "It needs protocol, auth, tls, tls_starttls, tls_trust_file,"
    printf >&2 "and logfile. Probably."
  fi
}


# $1: name
# $2: email address
# $3: in server address
# $4: in server port
# $5: out server address
# $6: out server port
imap_muttrc_template() {
  <<EOF cat -
# vim: filetype=neomuttrc

source ~/.config/neomutt/neomuttrc

# Some custom variables
set my_address = "${2}"

################################################################################
# General
################################################################################
# The in/out servers
set realname = \${my_name}
set imap_pass = "\`pass show email/\$my_address\`"
set folder = "imaps://\${my_address}@${3}:${4}"

## Using sendmail command intsead
#set smtp_url = "smtps://\${my_address}@${5}:${6}"
#set smtp_pass = "\`pass show email/\${my_address}\`"
set sendmail = "msmtp -a \${my_address}"

set spoolfile = "+INBOX"

# Identity configuration
set from = "\$my_name <\$my_address>"
set use_from = "yes"

################################################################################
# Mailboxes
################################################################################
# Use 'c' (change mailbox) then '<tab>' (toggle mailboxes) 
# So mutt knows where to move emails after you delete, etc.
# '+' is replaced {folder}
# ''... = +'Sent' '' or ''... = "+Sent" '' are both acceptable
set record = "+Sent"
set trash = "+Deleted"
set postponed = "+Drafts"

# Populates the sidebar and subscribes to mailboxes
# '=' is replaced {folder}
named-mailboxes "\${my_address}" =x       # Fake mailbox for sidebar
named-mailboxes "箱 Inbox"  =INBOX
named-mailboxes "稿 Drafts" ='Drafts'
named-mailboxes "送 Sent"   ='Sent'
named-mailboxes "廢 Junk"   ='Junk'
named-mailboxes "垃 Trash"  ='Deleted/'

# If we want multiple mailboxes at once, probably need this line
# account-hook \$folder "set imap_pass=..."
EOF
}

# $1: name
# $2: email address
# $3: in server address
# $4: in server port
# $5: out server address
# $6: out server port
oauth_muttrc_template() {
  <<EOF cat -
# vim: filetype=neomuttrc
# https://github.com/neomutt/neomutt/blob/main/contrib/oauth2/mutt_oauth2.py.README

source ~/.config/neomutt/neomuttrc

# Some custom variables
set my_address = "${2}"

################################################################################
# General
################################################################################
# The in/out servers
set realname = "${1}"
set folder = "imaps://\${my_address}@${3}:${4}"

set imap_authenticators = "oauthbearer:xoauth2"
set imap_oauth_refresh_command = "mutt_oauth2.py ${MUTT_TOKEN}"

# Not sure why this doesn't work
set smtp_url = "smtp://\${imap_user}@${5}:${6}/"
set smtp_authenticators = \${imap_authenticators}
set smtp_oauth_refresh_command = \${imap_oauth_refresh_command}

## Using sendmail command intsead
#set smtp_url = "smtps://\${my_address}@${5}:${6}"
#set smtp_pass = "\`pass show email/\${my_address}\`"
#set sendmail = "msmtp -a \${my_address}"

set spoolfile = "+INBOX"

# Identity configuration
set from = "\${realname} <\${my_address}>"
set use_from = "yes"

################################################################################
# Mailboxes
################################################################################
# Use 'c' (change mailbox) then '<tab>' (toggle mailboxes) 
# So mutt knows where to move emails after you delete, etc.
# '+' is replaced {folder}
# ''... = +'Sent' '' or ''... = "+Sent" '' are both acceptable
set record = "+[Gmail]/Sent Mail"
set trash = "+[Gmail]/Trash"
set postponed = "+[Gmail]/Drafts"

# Populates the sidebar and subscribes to mailboxes
# '=' is replaced {folder}
named-mailboxes "\${my_address}" =x  # Fake mailbox for sidebar
named-mailboxes "箱 Inbox"  =INBOX
named-mailboxes "稿 Drafts" ='[Gmail]/Drafts'
named-mailboxes "送 Sent"   ='[Gmail]/Sent Mail'
named-mailboxes "廢 Junk"   ='[Gmail]/Spam'
named-mailboxes "垃 Trash"  ='[Gmail]/Trash'

# If we want multiple mailboxes at once, probably need this line
# account-hook \$folder "set imap_pass=..."
EOF
}







# Not putting a
list_null_delimited_files() (
  for x in "${1}"/* "${1}"/.[!.]* "${1}"/..?*; do
    [ ! -e "${x}" ] && continue
    printf %s\\0 "${x#"${1}/"}"
  done
)

find_domain_for() (
  domain="${1##*@}"
  found=""
  for line in $( cat "${DOMAINS_CSV}" ); do
    glob_exp="${line%%,*}"
    if [ "${domain}" != "${domain#${glob_exp}}" ]; then
      printf %s\\n "${line}"
      return 0
    fi
  done
  return 1
)

# Helpers
outln() { printf %s\\n "$@"; }
die() { printf %s "${1}: " >&2; shift 1; printf %s\\n "$@" >&2; exit "${1}"; }
eval_escape() { <&0 sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"; }

<&0 main "$@"
