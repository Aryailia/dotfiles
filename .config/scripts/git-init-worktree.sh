name="${1##*/}"
name="${name%.git}"


case "${1}"
  # Use when you are in the "${name}/_bare" directory already
  in '')             bare="$( pwd )"
                     [ "${bare}" != "$( git rev-parse --show-toplevel )" ] && { printf %s\\n "Not in git root directory"; exit 1; }
  # Use when you are cloning an external
  ;; https:*|ssh:*)  bare="${name}/_bare"; mkdir -p "${bare}"; git -C "${bare}" clone --no-checkout "${1}" .

  # Use when you just have "${name}" project folder
  ;; *)              bare="${name}/_bare"; mkdir -p "${bare}"; git -C "${bare}" init
esac

if [ "" = "$( git -C "${bare}" branch --all --list )" ]; then
  # Commit an empty commit to work around not being able to add a branch to an empty repo
  git -C "${bare}"         checkout             -b        "_bare"
  git -C "${bare}"         commit --allow-empty --message "Init"
  git -C "${bare}"         worktree add         --detach  "../main"
  git -C "${bare}/../main" checkout             --orphan  "main"
  # Create 'main' as orphan, otherwise `git worktree add` will do it without orphan

else  # We have a default
  git -C "${bare}" checkout -b  "_bare"
  git -C "${bare}" worktree add "../main"
fi
