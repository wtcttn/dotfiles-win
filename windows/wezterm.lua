-- WezTerm Configuration
-- 最高にクールなターミナル設定 🚀

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============================================================================
-- 外観設定 (Appearance)
-- ============================================================================

-- カラースキーム: モダンでクールなテーマ
-- config.color_scheme = "Catppuccin Mocha" -- ダークで落ち着いた色合い
config.color_scheme = "Cappuccin Frappe" -- 明るくて爽やかな色合い
-- 他のおすすめ: 'Tokyo Night', 'Dracula', 'Nord', 'Gruvbox Dark'

-- 半透過背景設定
config.window_background_opacity = 0.4 -- 40%の透明度（クールで実用的）
config.win32_system_backdrop = "Acrylic" -- Windowsのアクリル効果
-- config.window_background_opacity = 0.8 -- 80%の透明度（クールで実用的）

-- フォント設定
config.font = wezterm.font_with_fallback({
	{ family = "Moralerspace Neon HWJPDOC", weight = "Regular" }, -- メインフォント
	{ family = "Moralerspace Argon HWJPDOC", weight = "Regular" }, -- フォールバック
	{ family = "JetBrains Mono", weight = "Regular" }, -- さらなるフォールバック
	{ family = "Consolas", weight = "Regular" },
})
config.font_size = 11.0
--config.line_height = 1.2
config.line_height = 1.2

-- ウィンドウ設定
config.window_decorations = "TITLE | RESIZE" -- タイトルバーを統合してクールに
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}

-- 初期ウィンドウサイズ（列数 x 行数）
config.initial_cols = 140 -- 横幅（文字数）
config.initial_rows = 40 -- 高さ（行数）

-- 背景エフェクト（さらにクールに）
config.window_background_gradient = {
	colors = { "#0f0f0f", "#1a1a1a" },
	orientation = { Linear = { angle = -45.0 } },
	interpolation = "Linear",
	blend = "Rgb",
}

-- カーソル設定
config.default_cursor_style = "BlinkingBar" -- 点滅するバーカーソル
config.cursor_blink_rate = 700
config.cursor_thickness = "2px"

-- ============================================================================
-- タブバー設定 (Tab Bar)
-- ============================================================================

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

-- タブバーの色設定
config.colors = {
	tab_bar = {
		background = "none",
		active_tab = {
			bg_color = "#89b4fa", -- Catppuccinのブルー
			fg_color = "#1e1e2e",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#313244",
			fg_color = "#cdd6f4",
		},
		inactive_tab_hover = {
			bg_color = "#45475a",
			fg_color = "#cdd6f4",
		},
		new_tab = {
			bg_color = "#1a1a1a",
			fg_color = "#89b4fa",
		},
		new_tab_hover = {
			bg_color = "#313244",
			fg_color = "#89b4fa",
			intensity = "Bold",
		},
	},
}

-- ============================================================================
-- デフォルトプログラム設定 (Default Program)
-- ============================================================================

-- WSLc の開発コンテナをデフォルトに設定
local wslc_dev = "C:\\Users\\kento\\dotfiles\\wslc-dev\\wezterm.cmd"
config.default_prog = { "cmd.exe", "/c", wslc_dev }

-- 起動プロファイル定義
config.launch_menu = {
	{
		label = "WSLc dev",
		args = { "cmd.exe", "/c", wslc_dev },
	},
	{
		label = "Arch Linux (WSL)",
		args = { "wsl.exe", "-d", "archlinux", "--cd", "~" },
	},
	{
		label = "PowerShell",
		args = { "pwsh.exe", "-NoLogo" },
	},
	{
		label = "Command Prompt",
		args = { "cmd.exe" },
	},
}

-- ============================================================================
-- キーバインド (Key Bindings)
-- ============================================================================

config.keys = {
	-- タブ操作
	{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },

	-- ペイン分割
	{ key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "_", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- ペイン移動
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },

	-- ペインサイズ調整
	{ key = "LeftArrow", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },

	-- フォントサイズ調整
	{ key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },

	-- コピー＆ペースト
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

	-- 検索
	{ key = "f", mods = "CTRL|SHIFT", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },

	-- ランチャー（クイックプロファイル切り替え）
	{ key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ShowLauncher },
}

-- ============================================================================
-- パフォーマンス最適化
-- ============================================================================

config.max_fps = 144 -- 高リフレッシュレートモニター対応
config.animation_fps = 60
config.scrollback_lines = 10000

-- ============================================================================
-- その他の便利な設定
-- ============================================================================

-- リンクのクリック検出
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- ファイルパスの検出を追加
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}:[\\/][\w\d\s\-\\/\\.]+)["]?]],
	format = "$1",
})

-- URLを開く際のデフォルトブラウザ設定
config.bypass_mouse_reporting_modifiers = "SHIFT"

-- ベル無効化（うるさくない）
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
}

-- マウス設定
config.mouse_bindings = {
	-- Ctrl+クリックでURLを開く
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- 右クリックでペースト
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- ============================================================================
-- デバッグ用（必要に応じてコメントアウト）
-- ============================================================================

-- wezterm.log_info('WezTerm configuration loaded successfully! 🚀')

return config
