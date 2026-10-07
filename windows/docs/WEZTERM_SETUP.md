# WezTerm セットアップガイド 🚀

Windows用の最高にクールなターミナルエミュレータ設定。

## 🎨 特徴

- **半透過背景**: 85%の透明度で背景が透ける美しいUI
- **Catppuccin Mochaテーマ**: モダンでダークな配色
- **WSL Arch Linuxデフォルト**: 起動時に自動でArch Linuxに接続
- **Moralerspace HWJPDOC**: 日本語+プログラミングに最適化されたフォント
- **高度なキーバインド**: 直感的なタブ・ペイン操作
- **高FPS対応**: 144Hzモニターで滑らかな表示

## 📦 インストール

### 前提条件

```powershell
# WezTermのインストール
winget install wez.wezterm
```

### 設定ファイルのインストール

```powershell
# PowerShellプロファイル + WezTerm設定を一括インストール
.\windows\install-powershell.ps1 install

# WezTerm設定のみをインストール
.\windows\install-powershell.ps1 wezterm
```

インストール後、WezTermを再起動すると設定が反映されます。

## ⌨️ キーボードショートカット

### タブ操作

| キー | 動作 |
|------|------|
| `Ctrl+Shift+T` | 新しいタブを開く |
| `Ctrl+Shift+W` | タブを閉じる（確認あり） |
| `Ctrl+Tab` | 次のタブへ移動 |
| `Ctrl+Shift+Tab` | 前のタブへ移動 |

### ペイン分割

| キー | 動作 |
|------|------|
| `Ctrl+Shift+\|` | 垂直分割 |
| `Ctrl+Shift+_` | 水平分割 |
| `Ctrl+Shift+矢印` | ペイン間を移動 |
| `Ctrl+Alt+矢印` | ペインサイズを調整 |

### フォント・表示

| キー | 動作 |
|------|------|
| `Ctrl+=` | フォントサイズを拡大 |
| `Ctrl+-` | フォントサイズを縮小 |
| `Ctrl+0` | フォントサイズをリセット |

### その他

| キー | 動作 |
|------|------|
| `Ctrl+Shift+C` | コピー |
| `Ctrl+Shift+V` | ペースト |
| `Ctrl+Shift+F` | 検索 |
| `Ctrl+Shift+L` | ランチャー（プロファイル切り替え） |
| `Ctrl+クリック` | URLを開く |
| `右クリック` | ペースト |

## 🎨 カスタマイズ

### カラースキームの変更

```lua
-- windows/wezterm.lua を編集
config.color_scheme = 'Tokyo Night' -- 他のテーマに変更

-- おすすめテーマ:
-- 'Catppuccin Mocha' (デフォルト)
-- 'Tokyo Night'
-- 'Dracula'
-- 'Nord'
-- 'Gruvbox Dark'
-- 'Solarized Dark'
```

### 透明度の調整

```lua
-- 完全に不透明にする場合
config.window_background_opacity = 1.0

-- より透明にする場合
config.window_background_opacity = 0.7

-- 推奨値: 0.75 - 0.9
```

### フォントサイズの変更

```lua
config.font_size = 11.0  -- デフォルト
-- サイズを変更: 10.0, 12.0, 13.0 など
```

### デフォルトシェルの変更

```lua
-- PowerShellをデフォルトにする場合
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- 別のWSLディストリビューションを使用する場合
config.default_prog = { 'wsl.exe', '-d', 'Ubuntu', '--cd', '~' }
```

## 🛠️ トラブルシューティング

### フォントが表示されない

1. WezTermを完全に再起動
2. フォントが正しくインストールされているか確認:
   ```powershell
   ls "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" | Select-String "Moralerspace"
   ```
3. 必要に応じて再インストール:
   ```powershell
   .\windows\install-powershell.ps1 font
   ```

### 透明度が効かない

- Windows 10/11のDWM（Desktop Window Manager）が有効か確認
- グラフィックドライバが最新か確認
- 古いバージョンのWindowsでは半透過が効かない場合があります

### WSLが起動しない

```powershell
# WSLの状態を確認
wsl --list --verbose

# Arch Linuxが存在するか確認
wsl -d Arch echo "OK"

# ディストリビューション名が異なる場合は windows/wezterm.lua を編集
```

### 設定が反映されない

```powershell
# 設定ファイルの場所を確認
ls C:\Users\kento\.wezterm.lua

# 構文エラーがないか確認（WezTermを起動してエラーメッセージを確認）

# 設定を再インストール
.\windows\install-powershell.ps1 wezterm
```

## 📚 参考リンク

- [WezTerm公式ドキュメント](https://wezfurlong.org/wezterm/)
- [Catppuccinカラースキーム](https://github.com/catppuccin/catppuccin)
- [Moralerspaceフォント](https://github.com/yuru7/moralerspace)
- [WezTerm設定例集](https://github.com/wez/wezterm/discussions/628)

## 🎯 次のステップ

1. **Oh My Poshを設定**: PowerShellをさらに美しく
   ```powershell
   winget install JanDeDobbeleer.OhMyPosh
   .\windows\install-powershell.ps1 install
   ```

2. **Zshをセットアップ**: WSL側でさらにパワフルなシェル体験
   ```bash
   cd ~/dotfiles
   ./archlinux/install.sh install
   ```

3. **カスタムテーマを作成**: `windows/wezterm.lua`を編集して自分好みに調整

---

**Enjoy your cool terminal! 🚀✨**

