local colors = require('sidebar-nvim.colors')
local severity_level = {"Error", "Warning", "Info", "Hint"}
local icons = {"", "", "", ""}
local use_icons = true

local function get_diagnostics(ctx)
    local messages = {}
    local hl = {}
    local current_buf = vim.api.nvim_get_current_buf()
    local open_bufs = vim.api.nvim_list_bufs()

    local all_diagnostics = vim.lsp.diagnostic.get_all()
    for number, diagnostics in pairs(all_diagnostics) do
      if number == current_buf then
        local file_path = vim.api.nvim_buf_get_name(current_buf)
        local split = vim.split(file_path, '/')
        local filename = split[#split]
        if next(diagnostics) ~= nil then
          local total = #diagnostics

          if total > 9 then total = '+' end
          local message = ' ' .. filename .. string.rep(' ', ctx.width - #filename - 8) .. total .. ' '
          table.insert(messages, message)
          table.insert(hl, { 'SidebarNvimLspDiagnosticsFileName', #messages, 0, #filename + 4 })
          table.insert(hl, { 'SidebarNvimLspDiagnosticsTotalNumber', #messages, ctx.width - 5, ctx.width})
        end
        for _, diag in pairs(diagnostics) do
            local message = diag.message
            message = message:gsub('\n', " ")
            local line = diag.range.start.line
            local line_length = 0
            if line > 0 then
              line_length = math.floor(math.log10(line) + 1)
            else
              line_length = 1
            end

            local severity = diag.severity
            local level = severity_level[severity]
            local icon = icons[severity]

            if use_icons then
              message = '│ ' .. icon .. " " .. line .. " " .. message
            else
              message = '│ ' .. level .. " " .. line .. " " .. message
            end

            if message:len() > (ctx.width) then
              message = message:sub(1, ctx.width - 3) .. '...'
            end

            table.insert(messages, message)

            -- Highlight separator
            table.insert(hl, { 'SidebarNvimLspDiagnosticsLineNumber', #messages, 0, 3 })
            -- Highlight Icon
            table.insert(hl, { 'SidebarNvimLspDiagnostics' .. level, #messages, 4, 8 })
            -- Highlight Line
            table.insert(hl, { 'SidebarNvimLspDiagnosticsLineNumber', #messages , 8, 8 + line_length })
        end
      elseif open_bufs[number] ~= nil and vim.api.nvim_buf_is_loaded(number) then
        local file_path = vim.api.nvim_buf_get_name(number)
        local split = vim.split(file_path, '/')
        local filename = split[#split]
        if next(diagnostics) ~= nil then
          local total = #diagnostics

          if total > 9 then total = '+' end
          local message = ' ' .. filename .. string.rep(' ', ctx.width - #filename - 8) .. total .. ' '
          table.insert(messages, message)
          table.insert(hl, { 'SidebarNvimLspDiagnosticsFileName', #messages, 0, #filename + 4 })
          table.insert(hl, { 'SidebarNvimLspDiagnosticsTotalNumber', #messages, ctx.width - 5, ctx.width - 2})
        end
      end
    end

    if messages == nil or #messages == 0 then
      return "<no diagnostics>"
    else
      return {
        lines = messages,
        hl = hl
      }
    end
end

return {
  title = "Diagnostics",
  icon = "📄",
  draw = function(ctx)
    return get_diagnostics(ctx)
  end,
  highlights = {
    -- { MyHLGroup = { gui=<color>, fg=<color>, bg=<color> } }
    groups = {
      SidebarNvimLspDiagnosticsError = {fg = colors.color.red},
      SidebarNvimLspDiagnosticsWarn = {fg = colors.color.orange},
      SidebarNvimLspDiagnosticsInfo = {fg = colors.color.cyan},
      SidebarNvimLspDiagnosticsHint = {fg = colors.color.cyan},
      SidebarNvimLspDiagnosticsLineNumber = {fg = colors.color.gray},
      SidebarNvimLspDiagnosticsFileName = {fg = colors.color.orange},
      SidebarNvimLspDiagnosticsTotalNumber = {fg = colors.color.white, bg = colors.color.orange},
    },
    links = {},
  },
}
