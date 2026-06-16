local project_markers = {
  "package.json",
  "Cargo.toml",
  "go.mod",
  "pyproject.toml",
  "setup.py",
  "CMakeLists.txt",
  "Makefile",
  "Gemfile",
  "composer.json",
  "mix.exs",
}

local function get_git_root(dir)
  local obj = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true, cwd = dir }):wait()
  if obj.code == 0 then
    return vim.trim(obj.stdout)
  end
  return nil
end

local function find_project_root(dir)
  local normalized = vim.fs.normalize(dir)
  local found = vim.fs.find(project_markers, { path = normalized, upward = true, limit = 1 })
  if #found > 0 then
    return vim.fs.dirname(found[1])
  end
  return nil
end

local function resolve_cwd(bufname)
  if bufname == "" then
    return nil
  end

  local dir = vim.fn.fnamemodify(bufname, ":h")
  if dir == "" then
    return nil
  end

  local git_root = get_git_root(dir)
  if git_root then
    return git_root
  end

  local project_root = find_project_root(dir)
  if project_root then
    return project_root
  end

  return dir
end

local augroup = vim.api.nvim_create_augroup("AutoCwd", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  callback = function()
    if vim.bo.buftype ~= "" then
      return
    end

    local bufname = vim.api.nvim_buf_get_name(0)
    local cwd = resolve_cwd(bufname)
    if cwd and vim.fn.isdirectory(cwd) == 1 and cwd ~= vim.fn.getcwd() then
      vim.fn.chdir(cwd)
    end
  end,
})
