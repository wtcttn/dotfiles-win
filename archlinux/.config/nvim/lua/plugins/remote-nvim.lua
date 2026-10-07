return {
  {
    "amitds1997/remote-nvim.nvim",
    -- "tnkgs/remote-nvim.nvim",
    version = "*", -- Pin to GitHub releases
    dependencies = {
      "nvim-lua/plenary.nvim", -- For standard functions
      "MunifTanjim/nui.nvim", -- To build the plugin UI
      "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
    },
    config = true,
    opts = {
      devpod = {
        binary = "devpod-cli",
      },
      client_callback = function(port, workspace_config)
        -- 新しいtmuxウィンドウの名前を設定 (例: "Remote: my-server")
        local window_name = ("Remote: %s"):format(workspace_config.host)
        -- 新しいウィンドウで実行するnvimクライアントコマンド
        local nvim_cmd = ("nvim --server localhost:%s --remote-ui"):format(port)

        local cmd = {
          "tmux",
          "new-window",
          "-n", -- 新しいウィンドウに名前を付けるオプション
          window_name, -- ウィンドウ名
          nvim_cmd, -- 実行するコマンド
        }
        -- tmuxコマンドを非同期で実行k
        vim.fn.jobstart(cmd, {
          detach = true,
          on_exit = function(job_id, exit_code, event_type)
            -- This function will be called when the job exits
            print("Client", job_id, "exited with code", exit_code, "Event type:", event_type)
          end,
        })
      end,
    },
  },
}
