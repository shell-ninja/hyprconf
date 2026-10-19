require("shell-ninja.core")
require("shell-ninja.lazy")

local ok, matugen = pcall(require, 'matugen')
if ok then matugen.setup() end
