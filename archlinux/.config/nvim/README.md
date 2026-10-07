# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## 📚 ドキュメント

- **[KEYBINDS.md](./KEYBINDS.md)** - キーバインドチートシート
- **[NEORG_KEYBINDS.md](./NEORG_KEYBINDS.md)** - Neorg専用キーバインド

## ✨ カスタマイズ

### 透明化設定

このNeovim設定は、Ghosttyターミナルと組み合わせて液体ガラス風の透明UIを実現します。

- **Ghostty**: 背景透明度85%、Catppuccin Mochaカラー
- **Neovim**: すべての背景を透明化（`transparent_background = true`）
- **Snacks Explorer**: ファイルエクスプローラーも完全透明

### キーバインド

- `<leader>` = `Space`（スペースキー）
- `<LocalLeader>` = `\`（バックスラッシュ）
- Neorgキーバインドは `<LocalLeader>n` プレフィックスに統一（衝突回避）

詳細は [KEYBINDS.md](./KEYBINDS.md) を参照してください。
