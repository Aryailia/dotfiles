#!/bin/sh
case "${1}"
  in "super Return") $TERMINAL -e tmux.sh open 
  ;; "alt super Return") alacritty -e tmux.sh open 
  ;; "ctrl super Return") st -e tmux.sh open 
  ;; "alt ctrl super Return") sakura -e tmux.sh open 
  ;; "shift super Return") $TERMINAL 
  ;; "alt shift super Return") alacritty 
  ;; "ctrl shift super Return") st 
  ;; "alt ctrl shift super Return") sakura 
  ;; "super d") dmenu_run 
  ;; "shift super Insert") notify.sh "Clipboard: $(xclip -o -selection clipboard)"
  notify.sh "Primary: $(xclip -o -selection primary)" 
  ;; "super BackSpace ; super q") sudo zzz -z 
  ;; "super BackSpace ; super w") printf %s\\n No Yes | dmenu -i -p     "Hibernate?"  | grep -q "Yes" && sudo zzz -Z 
  ;; "super BackSpace ; super e") printf %s\\n No Yes | dmenu -i -p      "Shutdown?"   | grep -q "Yes" && sudo shutdown -h now 
  ;; "super BackSpace ; super r") printf %s\\n No Yes | dmenu -i -p      "Reboot?"     | grep -q "Yes" && sudo reboot 
  ;; "super BackSpace ; super BackSpace") printf %s\\n No Yes | dmenu -i -p      "Close Xorg?" | grep -q "Yes" && killall Xorg 
  ;; "super BackSpace ; super t") xlock -mode blank 
  ;; "Print") flameshot gui 
  ;; "super space ; super w") $TERMINAL -e sh -c 'echo "nmcli"; echo "===="; sudo nmtui'; statusbar-startrefresh.sh 
  ;; "super space ; super e") $TERMINAL -e emacs-sandbox.sh -P -O d "${EMACSINIT}" 
  ;; "super space ; super a") $TERMINAL -e alsamixer; statusbar-startrefresh.sh 
  ;; "super space ; super s") $TERMINAL -e syncthing -no-browser 
  ;; "super space ; super z") $TERMINAL -e htop 
  ;; "super space ; super m") $TERMINAL -e tmux.sh open mw.sh 
  ;; "super space ; super n") $TERMINAL -e tmux.sh open newsboat 
  ;; "super u ; super q ; super q") fcitx-remote -s fcitx-keyboard-us-alt-intl-unicode 
  ;; "super u ; super q ; super w") fcitx-remote -s  fcitx-keyboard-cn-altgr-pinyin 
  ;; "super u ; super q ; super e") fcitx-remote -s  ipa-x-sampa 
  ;; "super u ; super w ; super q") fcitx-remote -s mozc 
  ;; "super u ; super w ; super w") fcitx-remote -s  anthy 
  ;; "super u ; super w ; super e") fcitx-remote -s  kkc 
  ;; "super u ; super e ; super q") fcitx-remote -s zhengma-large 
  ;; "super u ; super e ; super w") fcitx-remote -s  pinyin 
  ;; "super u ; super e ; super e") fcitx-remote -s  wbpy 
  ;; "super u ; super r ; super q") fcitx-remote -s jyutping 
  ;; "super u ; super r ; super w") fcitx-remote -s  rime 
  ;; "super u ; super r ; super e") fcitx-remote -s  chewing 
  ;; "super u ; super t ; super q") fcitx-remote -s hangul 
  ;; "super u ; super t ; super w") fcitx-remote -s hangul 
  ;; "super u ; super t ; super e") fcitx-remote -s hangul 
  ;; *) echo yo
esac
