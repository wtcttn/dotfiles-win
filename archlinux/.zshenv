# Arch Linuxの場合のみ設定
if [ -f /etc/arch-release ]; then
  # WSLでGPUビデオアクセラレーションレンダリングを有効にする
  export GALLIUM_DRIVER=d3d12
  export LIBVA_DRIVER_NAME=d3d12
  export MESA_LOADER_DRIVER_OVERRIDE=d3d12
  # export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
  
  # GTK設定 - X11を優先使用
  export GDK_BACKEND=x11
  # export GDK_GL=gl

  # xcvxrsを使用する場合
  # # wslのhost ipを取得
  # export HOST_IP=$(ipconfig.exe | iconv -f CP932 -t UTF-8 | sed -e 's/\r//' | grep 'IPv4' | tail -n 1 | cut -d ':' -f 2 | awk '{print $1}')
  # # Display変数にhost ipを設定 (VcXsrvを使用する場合)
  # export DISPLAY=$HOST_IP:0.0

  # Wayland環境変数設定
  export QT_QPA_PLATFORM=xcb

  # IME環境変数設定
  export GTK_IM_MODULE=fcitx
  export QT_IM_MODULE=fcitx
  export XMODIFIERS=@im=fcitx
fi

export LANG=ja_JP.UTF-8
