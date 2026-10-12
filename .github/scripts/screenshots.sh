#!/usr/bin/env bash
# Abre o WaveProject de verdade (AppImage) numa tela virtual e tira as
# capturas usadas na página do app no Project Club. Cada tela é uma ação
# real no programa (atalhos de teclado), nada é montado à mão.
#   uso: screenshots.sh <WaveProject.AppImage> <pasta-de-saída>
set -u
APP="$(readlink -f "$1")"; OUT="$(mkdir -p "$2" && readlink -f "$2")"
export DISPLAY=:99 QT_QPA_PLATFORM=xcb APPIMAGE_EXTRACT_AND_RUN=1 LANG=pt_BR.UTF-8 LC_ALL=C.UTF-8
export XDG_CONFIG_HOME="$HOME/.wp-config" XDG_DATA_HOME="$HOME/.wp-data"
Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp &
sleep 2
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true
pactl load-module module-null-sink sink_name=virtual 2>/dev/null || true

# Áudio de exemplo: uma "música" curta (acordes + batida) e uma voz sintética.
WORK=$(mktemp -d); cd "$WORK"
sox -n -r 44100 -c 2 chord.wav synth 16 pluck C3 pluck E3 pluck G3 pluck C4 fade 0 16 2 tremolo 4 40 gain -6
sox -n -r 44100 -c 2 beat.wav synth 0.12 sine 60 fade 0 0.12 0.1 pad 0 0.38 repeat 31 gain -2
sox -m chord.wav beat.wav musica.wav
sox -n -r 44100 -c 1 voz.wav synth 12 sine 220-660 tremolo 6 60 gain -8

n=0
shot() { n=$((n+1)); local f; f=$(printf '%s/%02d-%s.png' "$OUT" "$n" "$1"); sleep "${2:-2}"; import -window root "$f"; echo "captura: $f"; }
key() { xdotool key --clearmodifiers "$@"; }
win() { xdotool search --onlyvisible --name "$1" 2>/dev/null | head -1; }

"$APP" musica.wav > "$OUT/app.log" 2>&1 &
APP_PID=$!
sleep 40
shot abertura-assistente 1
# Assistente da primeira abertura: avança pelas páginas (tema, layout...).
for p in 1 2 3 4 5; do
  key Return; shot "assistente-$p" 3
done
key Escape; sleep 3
W=$(win "WaveProject"); [ -n "$W" ] && xdotool windowactivate --sync "$W" windowsize "$W" 1600 1000 windowmove "$W" 0 0 2>/dev/null
shot projeto-com-audio 4
key ctrl+f; shot ajustar-a-tela 3
key ctrl+a; shot selecao 3
key ctrl+equal ctrl+equal ctrl+equal; shot zoom 3
key ctrl+2; key ctrl+f; sleep 1
key e; shot efeitos-em-tempo-real 3
key Escape; sleep 1
key ctrl+shift+n; shot nova-faixa 3
key ctrl+shift+e; shot exportar 4
key Escape; sleep 2
key ctrl+comma; shot preferencias 4
key Tab Tab Down; shot preferencias-2 3
key Escape; sleep 2
key ctrl+shift+i; shot importar 4
key Escape; sleep 2
key ctrl+n; shot novo-projeto 5
kill $APP_PID 2>/dev/null; sleep 2
ls -la "$OUT"
