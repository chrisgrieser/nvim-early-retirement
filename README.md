# nvim-early-retirement 👴👵 <!-- rumdl-disable-line MD063 -->
<a href="https://dotfyle.com/plugins/chrisgrieser/nvim-early-retirement">
<img alt="badge" src="https://dotfyle.com/plugins/chrisgrieser/nvim-early-retirement/shield"/></a>

Send buffers into early retirement by automatically closing them after x minutes
of inactivity.

Makes the bufferline or `:bnext` less crowded.

<!-- toc -->

- [Installation](#installation)
- [Configuration](#configuration)
- [Similar Plugins](#similar-plugins)
- [Credits](#credits)

<!-- tocstop -->

## Installation

```lua
-- packer
use {
	"chrisgrieser/nvim-early-retirement",
	config = function () require("early-retirement").setup() end,
}

-- lazy.nvim
{
	"chrisgrieser/nvim-early-retirement",
	config = true,
	event = "VeryLazy",
},
```

## Configuration

```lua
defaultOpts = {
	-- If a buffer has been inactive for this many minutes, close it.
	retirementAgeMins = 20,

	-- Filetypes to ignore.
	ignoredFiletypes = {},

	-- Ignore files matching this lua pattern; empty string disables this setting.
	ignoreFilenamePattern = "",

	-- Will not close the alternate file.
	ignoreAltFile = true,

	-- Minimum number of open buffers for auto-closing to become active. E.g.,
	-- by setting this to 4, no auto-closing will take place when you have 3
	-- or fewer open buffers. Note that this plugin never closes the currently
	-- active buffer, so a number < 2 will effectively disable this setting.
	minimumBufferNum = 1,

	-- Ignore buffers with unsaved changes. If false, the buffers will
	-- automatically be written and then closed.
	ignoreUnsavedChangesBufs = true,

	-- Ignore non-empty buftypes, for example terminal buffers
	ignoreSpecialBuftypes = true,

	-- Ignore visible buffers. Buffers that are open in a window or in a tab
	-- are considered visible by vim. ("a" in `:buffers`)
	ignoreVisibleBufs = true,

	-- ignore unloaded buffers. Session-management plugin often add buffers
	-- to the buffer list without loading them.
	ignoreUnloadedBufs = false,

	-- Show notification on closing. Works with plugins like nvim-notify.
	notificationOnAutoClose = false,

	-- When a file is deleted, for example via an external program, delete the
	-- associated buffer as well. Requires Neovim >= 0.10.
	-- (This feature is independent from the automatic closing)
	deleteBufferWhenFileDeleted = false,

	-- Function to delete the buffer. The argument provided to the function is
	-- the buffer number. If nothing is provided the plugin will just call
	-- nvim_buf_delete.
	deleteFunction = nil,
}
```

> [!NOTE]
> You can also have `nvim-early-retirement` ignore certain buffers by setting
> `vim.b.ignore_early_retirement = true`.

## Similar plugins
- Close unedited files: [hbac](https://github.com/axkirillov/hbac.nvim)

## Credits
**Thanks** <!-- rumdl-disable-line MD036 -->
To `@nikfp` and `@xorg-dogma` on Discord for their help.

**About Me** <!-- rumdl-disable-line MD036 -->
In my day job, I am a sociologist studying the social mechanisms underlying the
digital economy. For my PhD project, I investigate the governance of the app
economy and how software ecosystems manage the tension between innovation and
compatibility. If you are interested in this subject, feel free to get in touch.

- [Website](https://chris-grieser.de/)
- [Mastodon](https://pkm.social/@pseudometa)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36'
style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'
border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
