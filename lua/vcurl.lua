local M = {}

local FILE = "/tmp/result.json"
M.run_curl_and_open_vsplit = function()
	local source_file = vim.fn.expand("%:p")
	local file = io.open(source_file, "r")
	if file == nil then
		print("Error opening file")
		return
	end

	local content = file:read("*a")
	content = string.gsub(content, "#[^\n]*\n", "")

	local curl = string.gsub(content, "\n", "")
	curl = string.gsub(curl, "curl", "curl --silent")

	local curl_output = vim.fn.system(curl .. " | jq")
	local response_buffer = io.open(FILE, "w")

	if response_buffer == nil then
		print("Error opening file")
		return
	end

	response_buffer:write(curl_output)
	response_buffer:close()

	-- Check if file is open, if so, dont create a vertical split
	local bufnr = vim.fn.bufnr(FILE)
	if bufnr ~= -1 then
		vim.cmd("bdelete " .. bufnr)
	end

	-- Open a new vertical split
	vim.cmd("vsplit" .. FILE)
end

return M
