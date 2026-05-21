return {
  {
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" }, -- 依存関係を明示
    opts = {
      -- バックエンド設定: WezTerm向けにSixelを指定
      backend = "sixel",
      -- プロセッサ設定: FFIバインディングを使用
      -- ビルドエラーが発生する場合は "magick_cli" に変更を検討
      processor = "magick_rock",
      -- 統合機能の設定
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          -- Sixelは描画コストが高いため、画面内の全画像を描画するとラグが生じる。
          -- カーソル位置の画像のみを描画することで体験を向上させる。
          only_render_image_at_cursor = true,
          -- ポップアップモードでの表示
          only_render_image_at_cursor_mode = "popup",
          -- フローティングウィンドウ制御:
          -- Sixelでのフローティング制御は難易度が高いため、トラブル時は無効化を検討
          floating_windows = false,
          -- markdown extensions (ie. quarto) can go here
          filetypes = { "markdown", "vimwiki" },
        },
        neorg = {
          enabled = true,
          filetypes = { "norg" },
        },
        html = { enabled = false },
        css = { enabled = false },
      },

      -- 画像サイズの制限
      -- 巨大な画像がターミナル全体を占有するのを防ぐ
      max_width = nil,
      max_height = nil,
      -- ウィンドウ高さの50%までに制限
      max_height_window_percentage = 50,
      max_width_window_percentage = nil,
      scale_factor = 1.0,

      -- エディタ動作設定
      -- フォーカス外では描画停止（CPU節約）
      editor_only_render_when_focused = true,
      -- Tmuxのアクティブウィンドウのみ描画
      tmux_show_only_in_active_window = true,

      -- ウィンドウ重複時のクリア設定
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },

      -- render image files as images when opened
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },
}
