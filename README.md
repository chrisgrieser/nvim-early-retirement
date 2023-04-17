# nvim-early-retirement 👴👵
Send buffers into early retirement by automatically closing them after x minutes of inactivity.

Makes the bufferline or `:bnext` less crowded.

<!--toc:start-->
- [Installation](#installation)
- [Configuration](#configuration)
- [Credits](#credits)
<!--toc:end-->

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
-- default values
opts = {
	-- if a buffer has been inactive for this many minutes, close it
	retirementAgeMins = 20,

	-- filetypes to ignore
	ignoredFiletypes = {},

	-- will not close the alternate file
	ignoreAltFile = true,

	-- minimum number of open buffers for auto-closing to become active, e.g.,
	-- by setting this to 4, no auto-closing will take place when you have 3 
	-- or less open buffers. Note that this plugin never closes the currently 
	-- active buffer, so a number < 2 will effectively disable this setting.
	minimumBufferNum = 1, 

	-- will ignore buffers with unsaved changes. If false, the buffers will
	-- automatically be written and then closed.
	ignoreUnsavedChangesBufs = true,

	-- ignore non-empty buftypes, for example terminal buffers
	ignoreSpecialBuftypes = true,

	-- ignore visible buffers ("a" in `:buffers`). buffers open in a window, 
	-- or in a tab are consider visible by vim
	ignoreVisibleBufs = true,

	-- ignore unloaded buffers. session-management plugin often add buffers
	-- to the buffer list without loading them
	ignoreUnloadedBufs = false,

	-- uses vim.notify for plugins like nvim-notify
	notificationOnAutoClose = false,
}
```

## Credits
__Thanks__  
To `@nikfp` and `@xorg-dogma` on Discord for their help.

<!-- vale Google.FirstPerson = NO -->
__About Me__  
In my day job, I am a sociologist studying the social mechanisms underlying the digital economy. For my PhD project, I investigate the governance of the app economy and how software ecosystems manage the tension between innovation and compatibility. If you are interested in this subject, feel free to get in touch.

__Blog__  
I also occasionally blog about vim: [Nano Tips for Vim](https://nanotipsforvim.prose.sh)

__Profiles__  
- [Discord](https://discordapp.com/users/462774483044794368/)
- [Academic Website](https://chris-grieser.de/)
- [GitHub](https://github.com/chrisgrieser/)
- [Twitter](https://twitter.com/pseudo_meta)
- [ResearchGate](https://www.researchgate.net/profile/Christopher-Grieser)
- [LinkedIn](https://www.linkedin.com/in/christopher-grieser-ba693b17a/)

__Buy Me a Coffee__  
<br>
<a href='https://ko-fi.com/Y8Y86SQ91' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
