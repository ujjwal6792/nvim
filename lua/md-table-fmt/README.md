# md-table-fmt.nvim

A zero-overhead Neovim plugin that auto-formats GitHub-Flavoured Markdown tables on save.

## Why?

Plugins like `markview.nvim` and `markview-smart-tables.nvim` render beautiful tables using `virt_lines` (virtual text overlays). These cause **scroll performance issues** because Neovim must repaint all virtual lines on every scroll step.

`md-table-fmt` takes a different approach: **it formats the real file content** on `BufWritePre`, so markview renders the already-aligned raw text with zero virtual-line overhead.

## What it does

- ✅ Aligns column widths (pads cells with spaces so all rows match)
- ✅ Normalises pipes and surrounding whitespace
- ✅ Adds missing trailing pipes
- ✅ Respects `:---:` / `---:` / `:---` alignment markers
- ✅ Preserves cursor position after formatting
- ✅ Pure Lua — no external dependencies

## Installation

### lazy.nvim (from a local path)

```lua
{
  dir = vim.fn.stdpath("config") .. "/lua/md-table-fmt",
  config = function()
    require("md-table-fmt").setup()
  end,
}
```

### Manual (no plugin manager needed)

Just add this to your `init.lua` or any sourced Lua file:

```lua
require("md-table-fmt").setup()
```

Because the files live under `~/.config/nvim/lua/`, Neovim finds them automatically.

## Configuration

```lua
require("md-table-fmt").setup({
  enabled          = true,                      -- set to false to disable globally
  filetypes        = { "markdown", "mdx" },     -- filetypes to auto-format
  min_column_width = 3,                         -- minimum content-area width per column
  padding          = 1,                         -- spaces on each side of cell text inside pipes
})
```

### Config options

| Option | Type | Default | Description |
|---|---|---|---|
| `enabled` | `boolean` | `true` | Enable/disable the plugin globally |
| `filetypes` | `string[]` | `{ "markdown", "mdx" }` | Which filetypes trigger auto-format on save |
| `min_column_width` | `integer` | `3` | Minimum content-area width in characters per column |
| `padding` | `integer` | `1` | Spaces added on each side of cell content |

## Commands

| Command | Description |
|---|---|
| `:MdTableFmt` | Format tables in the current buffer immediately |
| `:MdTableFmtOff` | Disable auto-formatting for the current buffer only |
| `:MdTableFmtOn` | Re-enable auto-formatting for the current buffer |

## Example

**Before save:**

```markdown
| Name | Age | City |
|---|---|---|
| Alice | 30 | New York |
| Bob | 25 | London |
| Charlie | 35 | Tokyo |
```

**After save:**

```markdown
| Name    | Age | City     |
| ------- | --- | -------- |
| Alice   | 30  | New York |
| Bob     | 25  | London   |
| Charlie | 35  | Tokyo    |
```

Alignment markers are respected:

**Before:**
```markdown
| Left | Center | Right |
|:--|:--:|--:|
| a | b | c |
```

**After:**
```markdown
| Left | Center | Right |
| :--- | :----: | ----: |
| a    |   b    |     c |
```

## Performance

Unlike virtual-line renderers, this plugin:
- Only runs on `BufWritePre` (not on every cursor move or scroll)
- Operates purely on buffer text — no extmarks, no virtual lines
- Has no scroll overhead whatsoever

## Per-buffer disable

To stop formatting a specific buffer without changing config:

```lua
-- In your config, e.g. via a keymap:
vim.keymap.set("n", "<leader>mf", require("md-table-fmt").disable_buf, { desc = "Disable md-table-fmt" })
```

Or interactively: `:MdTableFmtOff`
