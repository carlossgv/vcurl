local M = {}

local FILE = "/tmp/result.json"

local function get_lines_until_empty_or_eof(line_number)
	-- Get the buffer handle for the current buffer
	local buf = vim.api.nvim_get_current_buf()

	-- Initialize a table to store lines
	local lines = {}

	-- Get the total number of lines in the buffer
	local total_lines = vim.api.nvim_buf_line_count(buf)

	-- Start iterating from the given line number
	for line = line_number, total_lines do
		-- Get the line text
		local line_text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

		-- Check if the line is empty
		if line_text == "" or line_text:match("^ ") then
			-- If empty, stop iterating
			break
		end

		-- Append the line text to the table
		table.insert(lines, line_text)
	end

	-- Return the collected lines
	return lines
end

local function find_and_set_curl_line(target_line_number)
	-- Get the buffer handle for the current buffer
	local buf = vim.api.nvim_get_current_buf()

	-- Start iterating from the provided line number and move upwards
	for line = target_line_number, 1, -1 do
		print("line: ", line)
		-- Get the line text
		local line_text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]

		-- Check if the line starts with "curl"
		if line_text:match("^curl") then
			-- Set the line number to the found line
			vim.api.nvim_win_set_cursor(0, { line, 0 })
			-- Exit the loop as we found the line
			break
		end

		-- if line is empty or beginning of file, throw
		if line_text == "" or line_text:match("^ ") or line == 1 then
			return
		end
	end
end

M.run_curl_and_open_vsplit = function()
	-- Get the current line where the cursor is
	local current_line = vim.api.nvim_get_current_line()

	local original_line_number = vim.api.nvim_win_get_cursor(0)[1]

	-- if current line doesnt begin with curl, find the line that does
	if not current_line:match("^curl") then
		find_and_set_curl_line(original_line_number)
	end

	local line_number = vim.api.nvim_win_get_cursor(0)[1]

	-- check if content of this line begins with curl
	local line_content = vim.api.nvim_get_current_line()
	if not line_content:match("^curl") then
		print("No curl command found")
		return
	end

	local lines = get_lines_until_empty_or_eof(line_number)
	local content = table.concat(lines, "\n")
	content = string.gsub(content, "#[^\n]*\n", "")

	local curl = string.gsub(content, "\n", "")
	print("curl: ", curl)
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
