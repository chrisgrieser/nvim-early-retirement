local M = {}
local bufOpt = vim.api.nvim_buf_get_option

--------------------------------------------------------------------------------

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
		local isIgnoredSpecialBuffer = bufOpt(buf.bufnr, "buftype") ~= "" and c.ignoreSpecialBuftypes
		local isIgnoredAltFile = (buf.name == vim.fn.expand("#:p")) and c.ignoreAltFile
		local isModified = bufOpt(buf.bufnr, "modified")
		local isIgnoredUnsavedBuf = isModified and c.ignoreUnsavedChangesBufs
		local isIgnoredVisibleBuf = buf.hidden == 0 and buf.loaded == 1 and c.ignoreVisibleBufs
		local isIgnoredUnloadedBuf = buf.loaded == 0 and c.ignoreUnloadedBufs
		local isIgnoredFilename = c.ignoreFilenamePattern ~= "" and buf.name:find(c.ignoreFilenamePattern)

		if
			not recentlyUsed
			and not isIgnoredFt
			and not isIgnoredSpecialBuffer
			and not isIgnoredAltFile
			and not isIgnoredUnsavedBuf
			and not isIgnoredVisibleBuf
			and not isIgnoredUnloadedBuf
			and not isIgnoredFilename
		then
			if c.notificationOnAutoClose then
				local filename = vim.fs.basename(buf.name)
				vim.notify(filename, vim.log.levels.INFO, { title = "Auto-Closing Buffer" })
			end

			if isModified then vim.cmd.write() end
			vim.api.nvim_buf_delete(buf.bufnr, { force = false, unload = false })
		end
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

---@param config opts
function M.setup(config)
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
	}
	config = vim.tbl_deep_extend("keep", config, defaultConfig)

	-- https://neovim.io/doc/user/luvref.html#uv.new_timer()
	local timer = vim.loop.new_timer() 
	if not timer then return end
	-- schedule_wrap required for timers
	timer:start(config.retirementAgeMins * 60000, 10000, vim.schedule_wrap(function ()
		checkOutdatedBuffer(config)
	end))
end

--------------------------------------------------------------------------------
return M
