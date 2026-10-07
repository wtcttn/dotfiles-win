# Arch Linuxの場合のみ設定
if [ -f /etc/arch-release ]; then
  # WSLでGPUビデオアクセラレーションレンダリングを有効にする
  export GALLIUM_DRIVER=d3d12
  export LIBVA_DRIVER_NAME=d3d12
  export MESA_LOADER_DRIVER_OVERRIDE=d3d12

  # GTK設定 - X11を優先使用
  export GDK_BACKEND=x11

  # Wayland環境変数設定
  export QT_QPA_PLATFORM=xcb

  # IME環境変数設定
  export GTK_IM_MODULE=fcitx
  export QT_IM_MODULE=fcitx
  export XMODIFIERS=@im=fcitx
fi

export LANG=ja_JP.UTF-8
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export WORKSPACE="${WORKSPACE:-/workspace}"
