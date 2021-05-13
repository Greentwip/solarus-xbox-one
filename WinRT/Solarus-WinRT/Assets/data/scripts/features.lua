-- Sets up all non built-in gameplay features specific to this quest.

-- Usage: require("scripts/features")

-- Features can be enabled to disabled independently by commenting
-- or uncommenting lines below.

-- GUI scripts
require("scripts/menus/dialog_box")
require("scripts/menus/hud")
require("scripts/menus/stamina_gauge")

-- Meta scripts
require("scripts/meta/block")
require("scripts/meta/game")
require("scripts/meta/hero")
require("scripts/meta/item")
require("scripts/meta/map")
require("scripts/meta/npc")
require("scripts/meta/switch")
require("scripts/meta/camera")
require("scripts/meta/chest")

return true
