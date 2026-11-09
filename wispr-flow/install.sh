#!/usr/bin/env bash
# Install Wispr Flow (unofficial Linux port) the way the source Omarchy desk runs it.
# Run from a clone of this Handoff repo, inside a normal user session (not required
# to be graphical for download/extract; udev install and first GUI start need a seat).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WISPR_DIR="$(cd "$(dirname "$0")" && pwd)"
OPT="${HOME}/.local/opt/wispr-flow"
BIN="${HOME}/.local/bin"
VER="${WISPR_FLOW_VER:-1.6.1337-1.0.5}"
TAG_PATH='v1.0.5%2Bwispr1.6.1337'
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ARCH=aarch64 ;;
  x86_64|amd64)  ARCH=x86_64 ;;
  *) echo "Unsupported arch: $ARCH (need aarch64 or x86_64)"; exit 1 ;;
esac

APPIMAGE_NAME="wispr-flow-${VER}-${ARCH}.AppImage"
URL="https://github.com/wispr-flow-linux/wispr-flow-linux/releases/download/${TAG_PATH}/${APPIMAGE_NAME}"
DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
mkdir -p "$DOWNLOAD_DIR" "$BIN" "${HOME}/.config/systemd/user" \
  "${HOME}/.local/share/applications" \
  "${HOME}/.local/share/sounds/wispr-flow" \
  "${HOME}/.local/share/icons/hicolor/256x256/apps" \
  "${HOME}/.config/omarchy/plugins"

echo "==> Wispr Flow install (${VER}, ${ARCH})"
echo "    port: https://github.com/wispr-flow-linux/wispr-flow-linux"
echo "    url:  $URL"

if [[ ! -f "$DOWNLOAD_DIR/$APPIMAGE_NAME" ]]; then
  echo "==> Downloading AppImage"
  curl -L --fail --progress-bar -o "$DOWNLOAD_DIR/$APPIMAGE_NAME" "$URL"
fi
chmod +x "$DOWNLOAD_DIR/$APPIMAGE_NAME"

echo "==> Extracting to $OPT"
rm -rf "$OPT"
mkdir -p "$OPT"
# Extract into a temp dir then move — AppImage writes squashfs-root in cwd
tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT
cp "$DOWNLOAD_DIR/$APPIMAGE_NAME" "$tmp/"
(
  cd "$tmp"
  "./$APPIMAGE_NAME" --appimage-extract
  # shellcheck disable=SC2035
  shopt -s dotglob nullglob
  mv squashfs-root/* "$OPT"/
)

ln -sfn "$OPT/AppRun" "$BIN/wispr-flow"
echo "==> Launcher: $BIN/wispr-flow -> $OPT/AppRun"

install -m 644 "$WISPR_DIR/desktop/wispr-flow.desktop" \
  "${HOME}/.local/share/applications/wispr-flow.desktop"
if [[ -f "$OPT/ai.wisprflow.WisprFlow.png" ]]; then
  install -m 644 "$OPT/ai.wisprflow.WisprFlow.png" \
    "${HOME}/.local/share/icons/hicolor/256x256/apps/wispr-flow.png"
fi
update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

echo "==> systemd user units"
install -m 644 "$WISPR_DIR/systemd/wispr-flow.service" \
  "${HOME}/.config/systemd/user/wispr-flow.service"
install -m 644 "$WISPR_DIR/systemd/wispr-flow-sounds.service" \
  "${HOME}/.config/systemd/user/wispr-flow-sounds.service"

echo "==> sound daemon + WAVs"
install -m 755 "$WISPR_DIR/bin/wispr-flow-sound-daemon" "$BIN/wispr-flow-sound-daemon"
install -m 644 "$WISPR_DIR/sounds/"*.wav "${HOME}/.local/share/sounds/wispr-flow/"

echo "==> Omarchy bar panel (if Omarchy present)"
if [[ -d "${HOME}/.config/omarchy" && -d "$ROOT/local-plugins/wispr-flow-panel" ]]; then
  rsync -a "$ROOT/local-plugins/wispr-flow-panel/" \
    "${HOME}/.config/omarchy/plugins/wispr-flow-panel/"
  if command -v omarchy >/dev/null 2>&1; then
    omarchy plugin enable wispr-flow.panel 2>/dev/null || true
  fi
  echo "    panel installed -> ~/.config/omarchy/plugins/wispr-flow-panel/"
else
  echo "    skipped (no ~/.config/omarchy or panel missing in repo)"
fi

echo "==> udev rules (needs root once)"
if [[ -f "$WISPR_DIR/udev/70-wispr-flow-uinput.rules" ]]; then
  if command -v pkexec >/dev/null 2>&1; then
    echo "    Prefer after first graphical login:  wispr-flow --install-udev-rules"
  fi
  if [[ "${WISPR_INSTALL_UDEV:-}" == "1" ]]; then
    sudo install -m 644 "$WISPR_DIR/udev/70-wispr-flow-uinput.rules" \
      /usr/lib/udev/rules.d/70-wispr-flow-uinput.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "    udev installed"
  else
    echo "    NOT installed automatically. Run either:"
    echo "      wispr-flow --install-udev-rules"
    echo "      sudo cp $WISPR_DIR/udev/70-wispr-flow-uinput.rules /usr/lib/udev/rules.d/ && sudo udevadm control --reload-rules && sudo udevadm trigger"
    echo "    Or: WISPR_INSTALL_UDEV=1 bash $0"
  fi
fi

systemctl --user daemon-reload
if systemctl --user show-environment 2>/dev/null | rg -q 'WAYLAND_DISPLAY|DISPLAY='; then
  systemctl --user enable --now wispr-flow.service
  systemctl --user enable --now wispr-flow-sounds.service
  echo "==> services started"
else
  systemctl --user enable wispr-flow.service wispr-flow-sounds.service
  echo "==> services enabled; start after graphical login:"
  echo "      systemctl --user start wispr-flow wispr-flow-sounds"
fi

cat <<EOF

========================================================================
NEXT STEPS (do not skip)
========================================================================
1. udev (if not done):  wispr-flow --install-udev-rules
2. doctor:              wispr-flow --doctor
3. Start from GUI session if needed:
      systemctl --user start wispr-flow wispr-flow-sounds
4. Sign in via Hub:     xdg-open wispr-flow://open
5. Stop service and set PTT to Right Option (165) — see WISPR-FLOW.md §5
      systemctl --user stop wispr-flow
      # edit ~/.config/Wispr Flow/config.json  prefs.user.shortcuts["165"]="ptt"
      # hideFlowBarPermanently=true; personalizationStyles.other=\"casual\"
      systemctl --user start wispr-flow
6. Disable any other engine on Right Option (Voxtral Hypr binds) — DICTATION.md
7. Optional asar patches for pill/centering/close-to-background — WISPR-FLOW.md §6
8. omarchy restart shell   # pick up bar panel

Full runbook: $ROOT/WISPR-FLOW.md
========================================================================
EOF
