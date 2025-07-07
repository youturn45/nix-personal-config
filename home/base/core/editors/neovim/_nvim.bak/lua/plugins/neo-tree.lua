-- File explorer(Custom configs)
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- visible by default
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    git_status = {
      debounce_delay = 500, -- increase debounce delay
      sync_timeout = 5000, -- reduce sync timeout
    },
    git_status_async = true, -- enable async git status
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          vim.opt_local.relativenumber = true
        end,
      },
    },
  },
}
