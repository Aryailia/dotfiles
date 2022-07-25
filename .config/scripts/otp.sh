#!/bin/sh

# Decode the QR code from the clipboard

temp_filepath="$( mktemp )"
trap "rm -f \"${temp_filepath}\"" EXIT

xclip -selection clipboard -out -t image/png >"${temp_filepath}" || exit "$?"
code="$( zbarimg -q "${temp_filepath}" )" || exit "$?"
code="${code#QR-Code:}"


printf %s\\n "Copied the following to clipboard:" "" \
  "${code}" "" \
  "Add to via \`pass add <id> <paste>\`"
  >&2
clipboard.sh -w "${code}"


# output should be QR-Code:<URI>
# URI looks like <scheme>://activate_account?code=12345678&url...., e.g.
#    QR-Code:otpauth://totp/Example:alice@gnu.org?issuer=Example&secret=JBSWY3DPEHPK3PXP
# We want to copy everything after "QR-Code:"
# pass add <identifier> otpauth://...
# pass otp <identifier>
