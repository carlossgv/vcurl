local M = {}

local utils = require("utils")
local config = require("config")

local FILE = config.response_file

M.setup = function(user_config)
	if not user_config then
		user_config = {}
	end

	if user_config.split == "horizontal" then
		user_config.split = "split"
	else
		user_config.split = config.split
	end

	config = vim.tbl_deep_extend("force", config, user_config)
end

M.run = function()
	-- Get the current line where the cursor is
	local current_line = vim.api.nvim_get_current_line()

	local original_line_number = vim.api.nvim_win_get_cursor(0)[1]

	-- if current line doesnt begin with curl, find the line that does
	if not current_line:match("^curl") then
		utils.find_and_set_curl_line(original_line_number)
	end

	local line_number = vim.api.nvim_win_get_cursor(0)[1]

	-- check if content of this line begins with curl
	local line_content = vim.api.nvim_get_current_line()
	if not line_content:match("^curl") then
		print("No curl command found")
		return
	end

	local lines = utils.get_lines_until_empty_or_eof(line_number)
	local content = table.concat(lines, "\n")
	content = string.gsub(content, "#[^\n]*\n", "")

	local curl = string.gsub(content, "\n", "")
	curl = string.gsub(curl, "curl", "curl --silent")

	local curl_output = vim.fn.system(curl .. " | jq")
	local response_buffer = io.open(FILE, "w")

	if response_buffer == nil then
		print("Error opening reponse file")
		return
	end

	response_buffer:write(curl_output)
	response_buffer:close()

	-- Check if file is open, if so, dont create a vertical split
	local bufnr = vim.fn.bufnr(FILE)
	if bufnr ~= -1 then
		vim.cmd("bdelete " .. bufnr)
	end

	vim.cmd(config.split .. FILE)
end

return M
