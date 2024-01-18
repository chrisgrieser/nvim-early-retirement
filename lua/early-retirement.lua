local M = {}
local bufOpt = vim.api.nvim_buf_get_option

---@param msg string
local function notify(msg) vim.notify(msg, vim.log.levels.INFO, { title = "early-retirement" }) end

--------------------------------------------------------------------------------

local function deleteBufferWhenFileDeleted()
	vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
		callback = function(ctx)
			local bufnr = ctx.buf

			local isSet, setTrue = pcall(vim.api.nvim_buf_get_var, bufnr, "ignore_early_retirement")
			local isManuallyIgnored = isSet and setTrue
			if isManuallyIgnored then return end

			-- deferred to not interfere with new buffers
			vim.defer_fn(function()
				-- buffer has been deleted in the meantime
				if not vim.api.nvim_buf_is_valid(bufnr) then return end

				local bufname = vim.api.nvim_buf_get_name(bufnr)
				local isSpecialBuffer = bufOpt(bufnr, "buftype") ~= ""
				local fileExists = vim.loop.fs_stat(bufname) ~= nil
				local isNewBuffer = bufname == ""
				-- prevent the temporary buffers from conform.nvim's "injected"
				-- formatter to be closed by this. (filename is like "README.md.5.lua")
				local conformTempBuf = bufname:find("%.md%.%d+%.%l+$")

				if fileExists or isSpecialBuffer or isNewBuffer or conformTempBuf then return end

				notify(("%q does not exist anymore. Closing."):format(vim.fs.basename(bufname)))
				vim.api.nvim_buf_delete(bufnr, { force = false, unload = false })
			end, 100)
		end,
	})
end

---@param c opts effective config
local function checkOutdatedBuffer(c)
	local openBuffers = vim.fn.getbufinfo { buflisted = 1 } -- https://neovim.io/doc/user/builtin.html#getbufinfo
	if #openBuffers < c.minimumBufferNum then return end

	for _, buf in pairs(openBuffers) do
		-- check all the conditions
		local usedSecsAgo = os.time() - buf.lastused -- always 0 for current buffer, therefore it's never closed
		local recentlyUsed = usedSecsAgo < c.retirementAgeMins * 60

		local bufFt = bufOpt(buf.bufnr, "filetype")
		local isIgnoredFt = vim.tbl_contains(c.ignoredFiletypes, bufFt)

		local isModified = bufOpt(buf.bufnr, "modified")
		local isIgnoredUnsavedBuf = isModified and c.ignoreUnsavedChangesBufs

		local isIgnoredSpecialBuffer = bufOpt(buf.bufnr, "buftype") ~= "" and c.ignoreSpecialBuftypes
		local isIgnoredAltFile = (buf.name == vim.fn.expand("#:p")) and c.ignoreAltFile
		local isIgnoredVisibleBuf = buf.hidden == 0 and buf.loaded == 1 and c.ignoreVisibleBufs
		local isIgnoredUnloadedBuf = buf.loaded == 0 and c.ignoreUnloadedBufs
		local isIgnoredFilename = c.ignoreFilenamePattern ~= ""
			and buf.name:find(c.ignoreFilenamePattern)
		local isSet, setTrue = pcall(vim.api.nvim_buf_get_var, buf.bufnr, "ignore_early_retirement")
		local isManuallyIgnored = isSet and setTrue

		-- GUARD against any of the conditions
		if
			recentlyUsed
			or isIgnoredFt
			or isIgnoredSpecialBuffer
			or isIgnoredAltFile
			or isIgnoredUnsavedBuf
			or isIgnoredVisibleBuf
			or isIgnoredUnloadedBuf
			or isIgnoredFilename
			or isManuallyIgnored
		then
			goto continue
		end

		-- close buffer
		if c.notificationOnAutoClose then
			local filename = vim.fs.basename(buf.name)
			notify(("Auto-closing %q"):format(filename))
		end

		if isModified and not c.ignoreUnsavedChangesBufs then
			vim.api.nvim_buf_call(buf.bufnr, vim.cmd.write)
		end
		vim.api.nvim_buf_delete(buf.bufnr, { force = false, unload = false })

		::continue::
	end
end

--------------------------------------------------------------------------------

---@class opts
---@field retirementAgeMins number minutes after which an inactive buffer is closed
---@field ignoredFiletypes string[] list of filetypes to never close
---@field notificationOnAutoClose boolean list of filetypes to never close
---@field ignoreAltFile boolean whether the alternate file is also going to be ignored
---@field ignoreUnsavedChangesBufs boolean when false, will automatically write and then close buffers with unsaved changes
---@field ignoreSpecialBuftypes boolean ignore non-empty buftypes, e.g. terminal buffers
---@field ignoreVisibleBufs boolean ignore visible buffers (buffers open in a window, "a" in `:buffers`)
---@field ignoreUnloadedBufs boolean session plugins often add buffers without unloading them
---@field minimumBufferNum number minimum number of open buffers for auto-closing to become active
---@field ignoreFilenamePattern string ignore files matches this lua pattern (string.find)
---@field deleteBufferWhenFileDeleted boolean

---@param userConfig opts
function M.setup(userConfig)
	local defaultConfig = {
		retirementAgeMins = 20,
		ignoredFiletypes = { "lazy" },
		notificationOnAutoClose = false,
		ignoreAltFile = true,
		minimumBufferNum = 1,
		ignoreUnsavedChangesBufs = true,
		ignoreSpecialBuftypes = true,
		ignoreVisibleBufs = true,
		ignoreUnloadedBufs = false,
		ignoreFilenamePattern = "",
		deleteBufferWhenFileDeleted = false,
	}
	local config = vim.tbl_deep_extend("keep", userConfig, defaultConfig)

	local timer = vim.loop.new_timer()
	local checkingIntervalSecs = 30
	timer:start(
		config.retirementAgeMins * 60000,
		checkingIntervalSecs * 1000,
		-- schedule_wrap required for timers
		vim.schedule_wrap(function() checkOutdatedBuffer(config) end)
	)

	if config.deleteBufferWhenFileDeleted then deleteBufferWhenFileDeleted() end
end

--------------------------------------------------------------------------------
return M
