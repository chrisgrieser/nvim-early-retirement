local M = {}
local bufOpt = vim.api.nvim_buf_get_option
local ignoredFiletypes, retirementAgeMins, notificationOnAutoClose, ignoreAltFile, ignoreUnsavedChangesBufs, ignoreSpecialBuftypes, ignoreVisibleBufs, minimumBufferNum

--------------------------------------------------------------------------------

local function checkOutdatedBuffer()
	local openBuffers = vim.fn.getbufinfo { buflisted = 1 } -- https://neovim.io/doc/user/builtin.html#getbufinfo
	if #openBuffers < minimumBufferNum then return end

	for _, buf in pairs(openBuffers) do
		-- check all the conditions
		local usedSecsAgo = os.time() - buf.lastused -- always 0 for current buffer, therefore it's never closed
		local recentlyUsed = usedSecsAgo < retirementAgeMins * 60
		local bufFt = bufOpt(buf.bufnr, "filetype")
		local isIgnoredFt = vim.tbl_contains(ignoredFiletypes, bufFt)
		local isIgnoredSpecialBuffer = bufOpt(buf.bufnr, "buftype") ~= "" and ignoreSpecialBuftypes
		local isIgnoredAltFile = (buf.name == vim.fn.expand("#:p")) and ignoreAltFile
		local isModified = bufOpt(buf.bufnr, "modified")
		local isIgnoredUnsavedBuf = isModified and ignoreUnsavedChangesBufs
		local isIgnoredVisibleBuf = buf.hidden == 0 and ignoreVisibleBufs

		if
			not recentlyUsed
			and not isIgnoredFt
			and not isIgnoredSpecialBuffer
			and not isIgnoredAltFile
			and not isIgnoredUnsavedBuf
			and not isIgnoredVisibleBuf
		then
			if notificationOnAutoClose then
				local filename = vim.fs.basename(buf.name)
				vim.notify("Auto-Closing Buffer:\n" .. filename)
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
---@field minimumBufferNum number minimum number of open buffers for auto-closing to become active

---@param opts opts
function M.setup(opts)
	if not opts then opts = {} end
	-- default values
	retirementAgeMins = opts.retirementAgeMins or 20
	ignoredFiletypes = opts.ignoredFiletypes or { "lazy" }
	notificationOnAutoClose = opts.notificationOnAutoClose or false
	ignoreAltFile = opts.ignoreAltFile or true
	minimumBufferNum = opts.minimumBufferNum or 1
	ignoreUnsavedChangesBufs = opts.ignoreUnsavedChangesBufs or true
	ignoreSpecialBuftypes = opts.ignoreSpecialBuftypes or true
	ignoreVisibleBufs = opts.ignoreVisibleBufs or true

	local timer = vim.loop.new_timer() -- https://neovim.io/doc/user/luvref.html#uv.new_timer()
	if not timer then return end
	timer:start(0, 10000, vim.schedule_wrap(checkOutdatedBuffer)) -- schedule wrapper required for timers
end

--------------------------------------------------------------------------------
return M
