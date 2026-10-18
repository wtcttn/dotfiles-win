#!/bin/sh
# graf v1.1.0 を ~/.local/bin に入れる。
# note-graph-open と graf.toml は第1引数のディレクトリ（省略時はこのスクリプトの場所）が正。
# コンテナは引数なし。Mac は macos/install.sh が macos/ を渡す。
# Apple Silicon と Linux x86_64 だけ。チェックサムはリリースの SHA256SUMS。

set -eu

VERSION=1.1.0
BASE="https://github.com/reekta92/graf/releases/download/v${VERSION}"

if [ -n "${1:-}" ]; then
  ROOT=$1
else
  ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
fi

case "$(uname -s):$(uname -m)" in
  Linux:x86_64)
    name=graf-x86_64-unknown-linux-gnu.tar.gz
    sum=e30ac895aebe72cb04ddc928399aebe118709342c04cffdbb141ee932b9c0786
    ;;
  Darwin:arm64)
    name=graf-aarch64-apple-darwin.tar.gz
    sum=1a42d7a4db7b5dcce9103687c815b362ebac416558bf3fd564cdb82ed49c4106
    ;;
  *)
    echo "graf ${VERSION} のバイナリがありません: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

if [ ! -f "$ROOT/note-graph-open" ] || [ ! -f "$ROOT/graf.toml" ]; then
  echo "note-graph-open と graf.toml がありません: $ROOT" >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.config/graf" "$HOME/.local/share/graf"
stamp="$HOME/.local/share/graf/VERSION"

if [ ! -x "$HOME/.local/bin/graf" ] || [ "$(cat "$stamp" 2>/dev/null || true)" != "$VERSION" ]; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/graf.tar.gz" "$BASE/$name"
  if command -v sha256sum >/dev/null 2>&1; then
    got=$(sha256sum "$tmp/graf.tar.gz" | awk '{print $1}')
  else
    got=$(shasum -a 256 "$tmp/graf.tar.gz" | awk '{print $1}')
  fi
  if [ "$got" != "$sum" ]; then
    echo "チェックサムが違います: $got" >&2
    exit 1
  fi
  tar -xzf "$tmp/graf.tar.gz" -C "$tmp"
  install -m 755 "$tmp/graf" "$HOME/.local/bin/graf"
  printf '%s\n' "$VERSION" > "$stamp"
  trap - EXIT
  rm -rf "$tmp"
  echo "graf ${VERSION} を入れました"
else
  echo "graf ${VERSION} は入っています"
fi

cp "$ROOT/note-graph-open" "$HOME/.local/bin/note-graph-open"
chmod 755 "$HOME/.local/bin/note-graph-open"

dest="$HOME/.config/graf/config.toml"
if [ -e "$dest" ] && [ ! -L "$dest" ]; then
  mv "$dest" "$dest.backup"
  echo "既存の $dest を $dest.backup に退避しました"
fi
ln -sfn "$ROOT/graf.toml" "$dest"
echo "link: $dest -> $ROOT/graf.toml"
