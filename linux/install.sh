#!/usr/bin/env bash
# Installs Onstage as a desktop application: publishes the viewer to
# ~/.local/share/onstage, installs the .desktop entry and icon, and makes it the
# default handler for .glb/.gltf files (double-click in Files). Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINDIR="$HOME/.local/share/onstage"
APPDIR="$HOME/.local/share/applications"
ICONDIR="$HOME/.local/share/icons/hicolor/scalable/apps"

echo "publishing viewer to $BINDIR ..."
dotnet publish "$REPO/src/Onstage" -c Release -o "$BINDIR" --nologo -v q

# Remove the pre-rename ("GlbView") install so it cannot shadow Onstage.
rm -rf "$HOME/.local/share/glbview"
rm -f "$APPDIR/glbview.desktop" "$ICONDIR/glbview.svg"

install -Dm644 "$REPO/linux/onstage.svg" "$ICONDIR/onstage.svg"

install -d "$APPDIR"
# Escape the replacement for sed (&, \ and the | delimiter). The template quotes
# the whole Exec path, so a home directory containing spaces still parses.
escaped=$(printf '%s' "$BINDIR" | sed -e 's/[\\&|]/\\&/g')
sed -e "s|@BINDIR@|$escaped|" "$REPO/linux/onstage.desktop" > "$APPDIR/onstage.desktop"

if command -v update-desktop-database >/dev/null; then
    update-desktop-database "$APPDIR"
fi

# Claim the glTF MIME types from whatever owns them (e.g. Exhibit).
if command -v xdg-mime >/dev/null; then
    for mime in model/gltf-binary model/gltf+json; do
        xdg-mime default onstage.desktop "$mime"
    done

    echo "installed. glb/gltf files now open with Onstage:"
    xdg-mime query default model/gltf-binary
else
    echo "installed (xdg-mime not available; set the file association manually)."
fi
