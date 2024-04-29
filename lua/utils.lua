M = {}

function M.get_lines_until_empty_or_eof(line_number)
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

		-- remove whitespace from the beginning of the line
		line_text = line_text:gsub("^%s+", "")

		-- Check new curl line
		if line_text:match("^curl") and line > line_number then
			break
		end

		-- Check if the line is empty
		if line_text == "" then
			-- If empty, stop iterating
			break
		end

		-- Append the line text to the table
		table.insert(lines, line_text)
	end

	-- Return the collected lines
	return lines
end

function M.find_and_set_curl_line(target_line_number)
	-- Get the buffer handle for the current buffer
	local buf = vim.api.nvim_get_current_buf()

	-- Start iterating from the provided line number and move upwards
	for line = target_line_number, 1, -1 do
		-- Get the line text
		local line_text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1]
		-- remove whitespace from the beginning of the line
		line_text = line_text:gsub("^%s+", "")

		-- Check if the line starts with "curl"
		if line_text:match("^curl") then
			-- Set the line number to the found line
			vim.api.nvim_win_set_cursor(0, { line, 0 })
			-- Exit the loop as we found the line
			break
		end

		-- if line is empty or beginning of file, throw
		if line_text == "" or line == 1 then
			return
		end
	end
end

return M
