# Moralerspace HWJPDOC Font

## 自動インストール

```powershell
.\windows\install-powershell.ps1 install  # With profile
.\windows\install-powershell.ps1 font     # Font only
```

## 特徴

- 日本語・英語混在に最適化
- 等幅フォント（半角:全角 = 1:2）
- Nerd Font パッチ適用済み
- プログラミング向けグリフ

## バリエーション

- **Argon** (一般的)
- **Krypton** (丸み)
- **Neon** (シャープ) ← 推奨
- **Radon** (クラシック)
- **Xenon** (モダン)

## Windows Terminal設定

```json
{
  "font": {
    "face": "Moralerspace Neon HWJPDOC"
  }
}
```

または: `Ctrl+,` → Font face → `Moralerspace Neon HWJPDOC`

## インストール先

`%LocalAppData%\Microsoft\Windows\Fonts` (ユーザー、管理者権限不要)

## アンインストール

```powershell
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\Moralerspace*.ttf"
```

## リンク

- [Moralerspace](https://github.com/yuru7/moralerspace)
- [Releases](https://github.com/yuru7/moralerspace/releases)
- [License (SIL OFL 1.1)](https://scripts.sil.org/OFL)
