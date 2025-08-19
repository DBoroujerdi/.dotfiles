-- Minimal init.lua that bootstraps the modular config structure
-- Load core configuration modules first
require('config.options')
require('config.keymaps')
require('config.autocmds')

-- Load optional UI and command configurations
pcall(require, 'config.ui')
pcall(require, 'config.commands')

-- Load plugin manager and specifications
require('plugins')
