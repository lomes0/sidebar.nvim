local utils = require("sidebar-nvim.utils")
local luv = vim.loop

local status = {}
local hl = {}
local filenames = {}

local status_tmp = ""
local hl_tmp = {}

local function build_hl()
  hl_tmp = {}

  for i, _ in ipairs(status) do
    table.insert(hl_tmp, { 'SidebarNvimSectionKeyword', i, 0, 2 })
  end

  hl = hl_tmp
end

local function async_update()
  local stdout = luv.new_pipe(false)
  local stderr = luv.new_pipe(false)

  local handle
  handle, _  = luv.spawn("git", {
    args = {"status", "--porcelain"},
    stdio = {nil, stdout, stderr},
    cwd = luv.cwd(),
  }, function(_, _)

    filenames = {}
    if status_tmp == "" then
      status = "<no changes>"
      hl = {}
    else
      status = {}
      for _, line in ipairs(vim.split(status_tmp, '\n')) do
        local striped_line = line:match("^%s*(.-)%s*$")
        local line_status = striped_line:sub(0, 3)
        local line_filename = striped_line:sub(3, -1):match("^%s*(.-)%s*$")
        table.insert(status, line_status .. " " .. line_filename)

        if line_filename ~= "" then
          table.insert(filenames, line_filename)
        end
      end
      build_hl()
    end


    luv.read_stop(stdout)
    luv.read_stop(stderr)
    stdout:close()
    stderr:close()
    handle:close()
  end)

  status_tmp = ""

  luv.read_start(stdout, function(err, data)
    if data == nil then return end

    status_tmp = status_tmp .. data

    if err ~= nil then
      vim.schedule(function()
        utils.echo_warning(err)
      end)
    end
  end)

  luv.read_start(stderr, function(err, data)
    if data == nil then return end

    if err ~= nil then
      vim.schedule(function()
        utils.echo_warning(err)
      end)
    end

    --vim.schedule(function()
      --utils.echo_warning(data)
    --end)
  end)

end

return {
  title = "Git Status",
  icon = "📄",
  draw = function()
    async_update()
    return {
      lines = status,
      hl = hl,
    }
  end,
  highlights = {
    -- { MyHLGroup = { gui=<color>, fg=<color>, bg=<color> } }
    groups = {},
    -- { MyHLGroupLink = <string> }
    links = {},
  },
  bindings = {
    ["e"] = function(line)
      local filename = filenames[line]
      if filename == nil then
        return
      end
      vim.cmd("wincmd p")
      vim.cmd("e "..filename)
    end,
  },
}
