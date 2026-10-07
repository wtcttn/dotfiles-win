# 開発環境キーバインド チートシート

LazyVim + Ghostty + tmux + fcitx5 の統合キーバインドを IDE 風の操作体系でまとめました。  
日常的に使う操作を「入力メソッド → ターミナル → マルチプレクサ → エディタ」の順で把握できます。

**凡例**
- `<leader>` = `Space`
- `<LocalLeader>` = `\`
- 🟢: このリポジトリで追加・上書きしたカスタム
- 🔵: LazyVim / プラグイン / tmux などのデフォルト

---

## 0. 環境横断クイックリファレンス

| 操作カテゴリ | Ghostty (端末) | tmux (セッション) | Neovim (エディタ) | 備考 |
|--------------|----------------|-------------------|-------------------|------|
| 新規タブ / ウィンドウ | `Ctrl+Shift+T` 🟢 | `Prefix`+`c` 🔵 | `<leader>fn` 🔵 (新規ファイル) | `Prefix` = `Ctrl+g` |
| 画面分割 | - | `Prefix`+`|` 🟢（縦） / `Prefix`+`-` 🟢（横） | `<leader>w`系 🔵 | 画面管理は tmux が主担当 |
| ペイン移動 | OS 既定 | `Prefix`+`h/j/k/l` 🟢 | `<C-h/j/k/l>` 🟢 | tmux と Neovim の方向キーを統一 |
| コピペ | `Ctrl+Shift+C/V` 🟢 | マウスホイールで copy-mode 🟢 | `"+y`, `<leader>y` 🔵 | 端末 → tmux → Neovim の順に活用 |
| ズーム / フルスクリーン | `F11` 🟢 | `Prefix`+`z` 🔵 | `<leader>uz` 🔵 | フォーカスに応じて選択 |
| IME 切替 | `Ctrl+Space` | - | - | fcitx5 を経由して全レイヤーで共通 |

---

## 1. 入力メソッド（fcitx5）

```startLine:endLine:dotfiles/archlinux/.config/fcitx5/config
# ... existing code ...
TriggerKey=CTRL_SPACE
SwitchKey=SHIFT_SPACE
# ... existing code ...
```

| キー | アクション | 対象 |
|------|-----------|------|
| `Ctrl+Space` | Mozc ↔ 英数 切り替え | グローバル |
| `Shift+Space` | 半角 / 全角 切り替え | グローバル |

入力メソッドは `mozc` → `keyboard-us` の順番。`wayland` を無効化して WSLg/X11 で安定動作させています。

---

## 2. Ghostty（端末）

```startLine:endLine:dotfiles/archlinux/.config/ghostty/config
# ... existing code ...
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+shift+t=new_tab
keybind = ctrl+shift+w=close_surface
keybind = f11=toggle_fullscreen
keybind = ctrl+shift+comma=reload_config
# ... existing code ...
```

| キー | アクション | 用途 |
|------|-----------|------|
| `Ctrl+Shift+C` | クリップボードへコピー | tmux / Neovim の選択をそのままコピー |
| `Ctrl+Shift+V` | クリップボードから貼り付け | シェルへの貼り付け |
| `Ctrl+Shift+T` | 新規タブ | 作業スペースをすばやく増やす |
| `Ctrl+Shift+W` | 現在タブを閉じる | 終了ショートカット |
| `F11` | フルスクリーン切替 | 集中モード |
| `Ctrl+Shift+,` | 設定リロード | `~/.config/ghostty/config` を編集した後に |

---

## 3. tmux（セッション管理）

```startLine:endLine:dotfiles/archlinux/.tmux.conf
# ... existing code ...
set-option -g prefix C-g
bind | split-window -h
bind - split-window -v
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
set-option -g mouse on
# ... existing code ...
```

| キー | アクション | 種類 / 備考 |
|------|-----------|-------------|
| `Prefix` (`Ctrl+g`) | tmux コマンドモード | 🟢 |
| `Prefix`+`|` / `Prefix`+`-` | ペイン分割（縦 / 横） | 🟢 |
| `Prefix`+`h/j/k/l` | ペイン移動 | 🟢（Neovim と統一） |
| `Prefix`+`H/J/K/L` | ペインリサイズ ±5 | 🟢 |
| `Prefix`+`c` / `&` | 新規ウィンドウ / 閉じる | 🔵 |
| `Prefix`+`z` | ペインズーム | 🔵 |
| マウスホイール↑ | copy-mode へ入る | 🟢 |
| マウスホイール↓ | copy-mode を抜ける | 🟢 |
| `Prefix`+`Ctrl+s` / `Prefix`+`Ctrl+r` | セッション保存 / 復元 | 🔵 (`tmux-resurrect`) |

---

## 4. Neovim（LazyVim 基盤）

### 4-1. 画面 & バッファ操作

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `<leader>fs` | 保存 | - | 🟢 |
| `<leader>qq` | Neovim を終了 | - | 🔵 |
| `<S-h>` / `<S-l>` | バッファを前後移動 | - | 🟢 |
| `<leader>bd` / `<leader>bD` | バッファ削除 / 他バッファ一括削除 | - | 🟢 |
| `<C-h/j/k/l>` | ウィンドウ移動 | - | 🟢 |
| `<C-Up/Down/Left/Right>` | ウィンドウリサイズ ±2 | - | 🟢 |
| `<leader>ww`, `<leader>wm` | ウィンドウピッカー / 最大化 | LazyVim | 🔵 |

### 4-2. ファイル / プロジェクト

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `<leader>ff` | ファイル検索 | Telescope | 🔵 |
| `<leader>fr` | 最近使用ファイル | Telescope | 🔵 |
| `<leader>fg` | Ripgrep（プロジェクト検索） | Telescope | 🔵 |
| `<leader>fw` | カーソル下の単語を検索 | Telescope | 🔵 |
| `<leader>e` / `<leader>E` | Explorer (Snacks) | Snacks | 🟢 |
| `<leader>fe` | ファイルブラウザ（LazyVimデフォルト） | Snacks | 🔵 |
| `<leader>tl` | その場で翻訳 (JA) | Translate.nvim | 🟢 |

### 4-3. 編集支援

| キー | アクション | 種類 |
|------|-----------|------|
| `J` / `K` (Visual) | 選択行を上下に移動 | 🟢 |
| `<` / `>` (Visual) | インデント調整 + 選択維持 | 🟢 |
| `p` (Visual) | レジスタ保持で貼り付け | 🟢 |
| `J` (Normal) | 行連結 & カーソル保持 | 🟢 |
| `n` / `N` | 検索結果にジャンプ & 中央揃え | 🟢 |
| `j` / `k` | wrap 対応の移動 | 🟢 |
| `<Esc>` | 検索ハイライト解除 | 🟢 |
| `gcc`, `gc`, `gco`, `gcO` | コメント操作 | 🔵 (`Comment.nvim`) |

### 4-4. LSP / IDE 機能

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `gd`, `gD`, `gr`, `gI`, `gy` | ジャンプ各種 | nvim-lspconfig | 🔵 |
| `K`, `gK` | Hover / Signature Help | nvim-lspconfig | 🔵 |
| `<leader>ca`, `<leader>cr`, `<leader>cf` | Code Action / Rename / Format | nvim-lspconfig / conform | 🔵 |
| `]d` / `[d` | 診断メッセージ移動 | vim.diagnostic | 🔵 |
| `]e` / `[e`, `]w` / `[w` | Error / Warning 移動 | vim.diagnostic | 🔵 |
| `<leader>xx`, `<leader>xX` | Trouble（診断一覧） | trouble.nvim | 🔵 |

### 4-5. Git / バージョン管理

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `<leader>gg` | LazyGit UI | Snacks | 🟢 |
| `<leader>gs`, `<leader>gd`, `<leader>gb`, `<leader>gB` | Git ステータス / Diff / Blame / Branch | gitsigns.nvim | 🔵 |
| `<leader>ghs`, `<leader>ghp`, `<leader>ghr` | Hunk ステージ / プレビュー / リセット | gitsigns.nvim | 🔵 |
| `]h` / `[h` | Hunk 移動 | gitsigns.nvim | 🔵 |

### 4-6. ターミナル / ツール連携

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `<leader>tt` | フローティングターミナル | Snacks | 🟢 |
| `<leader>tT` | CWD に紐づけたターミナル | Snacks | 🟢 |
| `<C-/>` | ターミナル表示切替 | toggleterm.nvim | 🔵 |
| `<Esc><Esc>` (Terminal) | Normal モードへ戻る | - | 🟢 |
| `<C-h/j/k/l>` (Terminal) | ウィンドウ移動 | - | 🟢 |

### 4-7. UI / 各種ツール

| キー | アクション | プラグイン | 種類 |
|------|-----------|------------|------|
| `<leader>L` | Lazy UI | lazy.nvim | 🟢 |
| `<leader>un` | 通知をすべて閉じる | Snacks | 🟢 |
| `<leader>ul`, `<leader>uw`, `<leader>us` | 行番号 / Wrap / Spell トグル | LazyVim | 🔵 |
| `<leader>uc` | Colorscheme 切替 | LazyVim | 🔵 |
| `<leader>cm` | Mason UI | mason.nvim | 🔵 |

---

## 5. プラグイン固有メモ

- **Snacks.nvim**: Explorer (`<leader>e/E`), Terminal (`<leader>tt/tT`), Notifications (`<leader>un`), LazyGit (`<leader>gg`)
- **Translate.nvim**: `<leader>tl` で即座に日本語訳（選択範囲 / カーソル下）
- **Remote-Nvim.nvim**: コマンドライン (`:RemoteNvim`) や Telescope Picker から起動。キーバインドは未割当。
- **Which-Key.nvim**: `<leader>` を押してキーガイドを参照。`g`, `z`, `[` などのプリセットは無効化済みでノイズを削減。

---

## 6. Neorg（ドキュメント / タスク管理）

Neorg は `<LocalLeader>n` プレフィックスに統一。詳細は `NEORG_KEYBINDS.md` を参照。

| キー | 説明 |
|------|------|
| `<LocalLeader>nn` | Table of Contents |
| `<LocalLeader>nts` | タスク状態サイクル |
| `<LocalLeader>ntd/ntu/ntp/ntc` | Done / Undone / Pending / Cancelled |
| `<LocalLeader>n>` / `<LocalLeader>n<` | 見出しプロモート / デモート |
| `<LocalLeader>ncm` | コードブロック拡大表示 |

---

## 7. Which-Key の活用パターン

1. `<leader>` を押して利用可能なグループ（`f`, `g`, `c`, `t`, `u`, `s` …）を確認。
2. グループ → サブコマンドの順に 2 打以内で必要な操作に到達。
3. 途中で迷ったら `<Esc>` でキャンセル。

IDE 風の操作感に近づけるため、`<leader>f` = ファイル、`<leader>g` = Git、`<leader>c` = コード、`<leader>t` = ターミナル、`<leader>u` = UI と整理しています。

---

## 8. キーバインド追加のヒント

```lua
-- lua/config/keymaps.lua
local map = vim.keymap.set
map("n", "<leader>xx", "<cmd>YourCommand<CR>", { desc = "説明" })
```

Which-Key にグループを追加したい場合：

```lua
-- lua/plugins/which-key.lua
spec = {
  { "<leader>x", group = "Your Group" },
}
```

競合を避けるには、既存グループ（`f`, `g`, `t`, `u` など）に揃えるか、未使用の文字を Which-Key `spec` へ明示的に登録してください。

---

## 参考リンク

- [LazyVim 公式ドキュメント](https://www.lazyvim.org/)
- [Ghostty Config リファレンス](https://ghostty.org/docs/config)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Translate.nvim](https://github.com/uga-rosa/translate.nvim)
- [Neorg ドキュメント](https://github.com/nvim-neorg/neorg)

