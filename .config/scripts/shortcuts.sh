#!/bin/sh
case "${1}"
  in "ctrl super a ; super Return") st -e tmux.sh open 
  ;; "shift super a") fcitx-remote -o 
  ;; "super c ; super b") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'browser.sh print  bookmark | setsid clipboard.sh -w' 
  ;; "super c ; super c") printf %s '' | dmenu -p "Write to clipboard:" | setsid clipboard.sh --write 
  ;; "super c ; super e") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'setsid clipboard.sh -w "$(<~/.config/emoji fzf | cut -d " " -f 1)"' 
  ;; "super c ; super g") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'browser.sh print  link | setsid clipboard.sh -w' 
  ;; "super c ; super s") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'browser.sh print search | setsid clipboard.sh -w' 
  ;; "super g ; super a") handle.sh gui --file "$DOTENVIRONMENT/notes/cheatsheets/asciidoc-syntax-quick-reference.pdf" 
  ;; "super g ; super b") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'tmux.sh open browser.sh menu  bookmark' 
  ;; "super g ; super e") handle.sh gui --file "$DOTENVIRONMENT/notes/cheatsheets/emacs_cheatsheet.pdf" 
  ;; "super g ; super g") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'tmux.sh open browser.sh menu  link' 
  ;; "super g ; super s") $TERMINAL -t 'fullscreen_overlay' -e sh -c 'tmux.sh open browser.sh menu search' 
  ;; "ctrl shift super q") kill "$(xprop -id "$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)" '\t$0' _NET_WM_PID | cut -f 2)" 
  ;; "super u ; super e ; super e") notify.sh "zh-wubi"; fcitx-remote -s  wbpy 
  ;; "super u ; super e ; super q") notify.sh "zh-zhengma"; fcitx-remote -s zhengma-large 
  ;; "super u ; super e ; super w") notify.sh "zh"; fcitx-remote -s  pinyin 
  ;; "super u ; super q ; super e") notify.sh "XSampa"; fcitx-remote -s   ipa-x-sampa 
  ;; "super u ; super q ; super q") notify.sh "en"; fcitx-remote -s   fcitx-keyboard-us-alt-intl-unicode 
  ;; "super u ; super q ; super w") notify.sh "en-pinyin"; fcitx-remote -s   fcitx-keyboard-cn-altgr-pinyin 
  ;; "super u ; super r ; super e") notify.sh "zh-chewing"; fcitx-remote -s  chewing 
  ;; "super u ; super r ; super q") notify.sh "ca-jyutping"; fcitx-remote -s jyutping 
  ;; "super u ; super r ; super w") notify.sh "rime"; fcitx-remote -s  rime 
  ;; "super u ; super t ; super q") notify.sh "kr"; fcitx-remote -s hangul 
  ;; "super u ; super w ; super e") notify.sh "jp-kkc"; fcitx-remote -s  kkc 
  ;; "super u ; super w ; super q") notify.sh "jp-mozc"; fcitx-remote -s mozc 
  ;; "super u ; super w ; super w") notify.sh "jp-anthy"; fcitx-remote -s  anthy 
  ;; "Print") flameshot gui 
  ;; "super space ; super a") $TERMINAL -e alsamixer; statusbar-startrefresh.sh 
  ;; "super space ; super e") $TERMINAL -e emacs-sandbox.sh -P -O d "${EMACSINIT}" 
  ;; "super space ; super m") $TERMINAL -e tmux.sh open mw.sh 
  ;; "super space ; super n") $TERMINAL -e tmux.sh open newsboat 
  ;; "super space ; super s") $TERMINAL -e syncthing -no-browser 
  ;; "super space ; super w") $TERMINAL -e sh -c 'echo "nmcli"; echo "===="; sudo nmtui'; statusbar-startrefresh.sh 
  ;; "super space ; super z") $TERMINAL -e htop 
  ;; "shift super Insert") notify.sh "Clipboard: $(xclip -o -selection clipboard)"
  notify.sh "Primary: $(xclip -o -selection primary)" 
  ;; "super Return") $TERMINAL -e tmux.sh open 
  ;; "alt super Return") alacritty -e tmux.sh open 
  ;; "alt ctrl super Return") sakura -e tmux.sh open 
  ;; "shift super Return") $TERMINAL 
  ;; "alt shift super Return") alacritty 
  ;; "ctrl shift super Return") st 
  ;; "alt ctrl shift super Return") sakura 
  ;; "super BackSpace ; super e") printf %s\\n No Yes | dmenu -i -p      "Shutdown?"   | grep -q "Yes" && sudo shutdown -h now 
  ;; "super BackSpace ; super q") sudo zzz -z 
  ;; "super BackSpace ; super r") printf %s\\n No Yes | dmenu -i -p      "Reboot?"     | grep -q "Yes" && sudo reboot 
  ;; "super BackSpace ; super t") xlock -mode blank 
  ;; "super BackSpace ; super w") printf %s\\n No Yes | dmenu -i -p     "Hibernate?"  | grep -q "Yes" && sudo zzz -Z 
  ;; "super BackSpace ; super BackSpace") printf %s\\n No Yes | dmenu -i -p      "Close Xorg?" | grep -q "Yes" && killall Xorg 
  ;; "XF86MonBrightnessUp") xbacklight + 10; statusbar-startrefresh.sh 
  ;; "XF86MonBrightnessDown") xbacklight - 10; statusbar-startrefresh.sh 
  ;; *) notify.sh "key combination ${1}"; exit 1
esac
