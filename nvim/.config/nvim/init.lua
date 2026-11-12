if vim.loader then
	vim.loader.enable()
end

-- _G.dd = function(...)
--     require("util.debug").dump(...)
-- end
-- vim.print = _G.dd

_G.Vicmartos = require("vicmartos.utils")
require("vicmartos.config.options")
require("vicmartos.config.keymaps")
require("vicmartos.config.autocmds")
require("vicmartos.config.commands")
require("vicmartos.config.workarounds")
require("vicmartos.plugins")
