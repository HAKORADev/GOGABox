#!/usr/bin/env bash
# ============================================================================
# v0.3.8-6 THE FILM RIG v2 - one-shot visual evidence session.
# Boots Xvfb, runs ONE scene, films real gameplay with x11grab ONCE and
# dumps periodic PNG stills with a SECOND single ffmpeg (no reconnects).
# Usage: tools/v038p6_film.sh <scene> <seconds> <outprefix> [WxH]
# ============================================================================
set -u
GODOT="/home/z/my-project/gogabox/.cache/godot/bin/godot"
PROJ="/home/z/my-project/gogabox/projects/gogabox"
SCENE="${1:-res://tests/rec_domino.tscn}"
SECS="${2:-40}"
OUT="${3:-/tmp/film/domino}"
GEOM="${4:-1080x1920x24}"
WIN="${GEOM%x*}"
RES="${5:-}"   # optional Godot window size, e.g. 1920x1080
RES_ARG=""
[ -n "$RES" ] && RES_ARG="--resolution $RES"

pkill -f "Xvfb :97" 2>/dev/null; pkill -f "x11grab" 2>/dev/null; sleep 0.5
Xvfb :97 -screen 0 "$GEOM" -nolisten tcp &
XVFB_PID=$!
sleep 2
export DISPLAY=:97

ffmpeg -y -loglevel error -f x11grab -video_size "$WIN" -i :97 \
        -r 12 -c:v libx264rgb -preset ultrafast -crf 18 "$OUT.mp4" &
FF_PID=$!

ffmpeg -y -loglevel error -f x11grab -video_size "$WIN" -i :97 \
        -vf "fps=1/4" "$OUT""_t%03d.png" &
ST_PID=$!

"$GODOT" --path "$PROJ" $RES_ARG "$SCENE" &
GODOT_PID=$!

sleep "$SECS"

kill $GODOT_PID $ST_PID $FF_PID 2>/dev/null
sleep 1
kill $XVFB_PID 2>/dev/null
wait 2>/dev/null
echo "FILM DONE: $OUT.mp4 + stills (${SECS}s)"
