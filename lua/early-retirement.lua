local M = {}
local uv = vim.uv or vim.loop -- backwards compatibility with neovim <= 0.9

local function bufOpt(bufnr, opt)
	if vim.api.nvim_get_option_value then
		return vim.api.nvim_get_option_value(opt, { buf = bufnr })
	else
		---@diagnostic disable-next-line: deprecated -- backwards compatibility
		return vim.api.nvim_buf_get_option(bufnr, opt)
	end
end

---@param msg string
---@param level? "info"|"trace"|"debug"|"warn"|"error"
local function notify(msg, level)
	local notifyLevel = level and vim.log.levels[level:upper()] or vim.log.levels.INFO
	vim.notify(msg, notifyLevel, { title = "early-retirement" })
end

--------------------------------------------------------------------------------

local function deleteBufferWhenFileDeleted()
	local version = vim.version()
	if version.major == 0 and version.minor < 10 then
		notify("`deleteBufferWhenFileDeleted` requires at least nvim 0.10.", "warn")
		return
	end

	vim.api.nvim_create_autocmd("FocusGained", {
		callback = function()
			local closedBuffers = {}
			vim.iter(vim.api.nvim_list_bufs())
				:filter(function(bufnr)
					local valid = vim.api.nvim_buf_is_valid(bufnr)
					local loaded = vim.api.nvim_buf_is_loaded(bufnr)
					return valid and loaded
				end)
				:filter(function(bufnr)
					local bufPath = vim.api.nvim_buf_get_name(bufnr)
					local doesNotExist = uv.fs_stat(bufPath) == nil
					local notSpecialBuffer = vim.bo[bufnr].buftype == ""
					local notNewBuffer = bufPath ~= ""
					return doesNotExist and notSpecialBuffer and notNewBuffer
				end)
				:each(function(bufnr)
					local bufName = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
					table.insert(closedBuffers, bufName)
					vim.api.nvim_buf_delete(bufnr, { force = true })
				end)
			if #closedBuffers == 0 then return end

			if #closedBuffers == 1 then
				notify("Buffer closed: " .. closedBuffers[1])
			else
				local text = "- " .. table.concat(closedBuffers, "\n- ")
				notify("Buffers closed:\n" .. text)
			end
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

	local timer = uv.new_timer()
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
