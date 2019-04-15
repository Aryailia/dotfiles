#!/bin/sh

#####
# Stuff you can configure
#####
# package checker for your distribution
package_installed_check="xbps-query"
# Links to the imes to install. Do not put the .git at the end
imes_to_add="
  https://gitlab.com/fcitx/fcitx-hangul
  https://gitlab.com/fcitx/fcitx-table-extra
  https://gitlab.com/fcitx/fcitx-table-other
"
  # https://gitlab.com/fcitx/fcitx-googlepinyin
  # https://gitlab.com/fcitx/fcitx-zhuyin
# directory that these git files will be saved to
temp="$HOME/ime"



# Dependency check
# Googlepinyin needs ?? (I have not gotten this working yet)
# Hangul needs libhangul-devel
echo "Note: only need libhangul-devel for installing korean"
has_dependencies=1
dependents="git base-devel cmake fcitx-devel libhangul-devel"

for package in $dependents; do
  if [ -z "$($package_installed_check "$package")" ]; then
    echo "$package is a dependecy and is not installed"
    has_dependencies=0
  fi
done

# Keep track the stati of the imes for report at the end
success=""
already=""
failed=""

if [ $has_dependencies -eq 1 ]; then
  [ -d "$temp" ] || mkdir -p "$temp"
  for link in $imes_to_add; do
    ime=${link##*/}
    cd "$temp" || exit

    if [ -d "$ime" ]; then
      already="$already $ime"
    else
      git clone "$link.git $temp/$ime"
      mkdir "${ime}/build"
      cd "${ime}/build" || exit
      cmake ..


      # Run it again for the errors, should not cause problems
      error="$(cmake .. 2>&1 >/dev/null)"

      # Only run the make if no errors occured
      if [ -z "$error" ]; then
        error=$(sudo make install 2>&1 >/dev/null)

        # final error check
        if [ -z "$error" ]; then
          success="$success $ime"
        else
          failed="$failed $ime"
        fi
      else
        failed="$failed $ime"
      fi

    fi
  done

  # Report
  echo "---"
  echo "{$success } succeded"
  echo "{$already } already were downloaded/installed"
  echo "{$failed } failed"
fi
