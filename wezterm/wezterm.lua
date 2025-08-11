local wezterm = require("wezterm")
local cyberduck_ssh = require("cyberduck_ssh") -- Import our cyberduck module
local cyberduck_debug = require("cyberduck_ssh_debug") -- Debug version
local ssh_launcher = require("ssh_launcher_export") -- Import SSH launcher module with export/import

local config = wezterm.config_builder()

-- ========================================
-- THEME SWITCHER - Change this line to switch themes!
-- ========================================
local current_theme = "melange"  -- Options: "melange" or "catppuccin"
-- Alternative: Set environment variable WEZTERM_THEME=catppuccin or WEZTERM_THEME=melange
-- local current_theme = os.getenv("WEZTERM_THEME") or "melange"

-- General Settings
config.automatically_reload_config = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = true  -- enabled for better appearance with custom styling
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE | RESIZE"
config.webgpu_power_preference = "LowPower"

-- Font Settings
config.font = wezterm.font("JetBrains Mono", {
    weight = "DemiBold",
})
config.font_size = 15.5

-- Window Size Settings
config.initial_cols = 120  -- Default 80 * 1.5
config.initial_rows = 36   -- Default 24 * 1.5

-- Window Padding
config.window_padding = {
    left = "3cell",
    right = "3cell",
    top = "0cell",
    bottom = "0cell",
}

-- Background Opacity
config.window_background_opacity = 0.9
config.macos_window_background_blur = 0
config.front_end = "WebGpu"

-- Cursor Customization
config.cursor_blink_rate = 500  -- Blink rate in milliseconds
config.cursor_thickness = "0.2cell"
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "BlinkingBlock"
-- Tab Bar Customization: Using fancy tab bar with custom styling (disabled above)
config.tab_max_width = 50  -- Generous width to avoid truncation
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false  -- Disable tab numbers for cleaner look
config.show_new_tab_button_in_tab_bar = true

-- Custom tab title formatting for fancy tabs
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local process = string.gsub(tab.active_pane.foreground_process_name or '', '(.*[/\\])(.*)', '%2')
    local pane = tab.active_pane
    
    -- Simple icon mapping for common processes
    local icons = {
        ['Python'] = '🐍',
        ['python'] = '🐍',
        ['python3'] = '🐍',
        ['zsh'] = '💻',
        ['bash'] = '💻',
        ['node'] = '⚡',
        ['docker'] = '🐳',
        ['kubectl'] = '☸️',
        ['k9s'] = '☸️',
        ['ssh'] = '🌐',
        ['sshpass'] = '🌐', -- Same icon as SSH
        ['nvim'] = '📝',
        ['vim'] = '📝',
        ['git'] = '📋',
        ['go'] = '🐹',
        ['java'] = '☕',
        ['ruby'] = '💎',
        ['rust'] = '🦀',
        ['cargo'] = '🦀',
    }

    local icon = icons[process] or icons[string.lower(process)] or '💻'
    
    -- For SSH connections, use the custom title if it's been set
    local display_name = process
    if (process == 'ssh' or process == 'sshpass') then
        icon = '🌐' -- Ensure SSH icon
        -- Check if we have a custom title set via set_title()
        if tab.tab_title and tab.tab_title ~= "" then
            display_name = tab.tab_title
        end
    end
    
    local display_title = '  ' .. icon .. '  ' .. display_name .. '  '

    return display_title
end)

-- Enhanced status line
wezterm.on('update-right-status', function(window, pane)
    local date_time = wezterm.strftime '%d-%m-%Y %H:%M:%S'

    window:set_right_status(wezterm.format {
        { Foreground = { Color = '#9ACD32' } }, -- Light yellow-green to match cursor
        { Text = '📅 ' .. date_time .. ' ' },
    })
end)

-- ========================================
-- DYNAMIC THEME APPLICATION
-- ========================================
if current_theme == "catppuccin" then
    -- Catppuccin Mocha Theme
    config.color_scheme = "Catppuccin Mocha"
    config.colors = {
        tab_bar = {
            background = "#181825", -- Catppuccin mantle
            active_tab = {
                bg_color = "#fab387", -- Catppuccin Mocha peach (orange)
                fg_color = "#1e1e2e", -- Catppuccin base for contrast
                intensity = "Bold",
            },
            inactive_tab = {
                bg_color = "#313244", -- Catppuccin surface0
                fg_color = "#cdd6f4", -- Catppuccin text
            },
            inactive_tab_hover = {
                bg_color = "#45475a", -- Catppuccin surface1
                fg_color = "#f5e0dc", -- Catppuccin rosewater
            },
            new_tab = {
                bg_color = "#313244", -- Catppuccin surface0
                fg_color = "#89b4fa", -- Catppuccin blue button
            },
            new_tab_hover = {
                bg_color = "#45475a", -- Catppuccin surface1
                fg_color = "#89dceb", -- Catppuccin sky on hover
            },
        },
    }
else
    -- Melange Theme (Default)
    config.colors = {
        foreground = "#ede0c8", -- Much lighter warm beige text
        background = "#2d2721", -- Melange dark brown background
        cursor_bg = "#9ACD32",   -- Light yellow-green cursor
        cursor_fg = "#2d2721",   -- Dark cursor text
        cursor_border = "#9ACD32", -- Light yellow-green cursor border
        selection_bg = "#4f4135", -- Melange medium brown selection
        selection_fg = "#ede0c8", -- Much lighter beige text

        -- ANSI colors (Melange-inspired palette with MAXIMUM brightness for commands/flags)
        ansi = {
            "#4f4135", -- black (medium brown)
            "#e89664", -- red (lighter warm orange)
            "#f0f0c0", -- green (nearly white-green for commands)
            "#ffffc0", -- yellow (nearly pure white-yellow for flags/arguments)
            "#a1b2d6", -- blue (lighter muted blue)
            "#d6a0d6", -- magenta (lighter warm purple)
            "#a1d6d6", -- cyan (lighter muted teal)
            "#ede0c8", -- white (much lighter warm beige)
        },
        brights = {
            "#726450", -- bright black (darker brown)
            "#f0a876", -- bright red (even lighter orange)
            "#fafad0", -- bright green (almost pure white-green for commands)
            "#ffffcc", -- bright yellow (pure white-yellow for flags/arguments)
            "#b8c9e8", -- bright blue (even lighter blue)
            "#e8b8e8", -- bright magenta (even lighter purple)
            "#b8e8e8", -- bright cyan (even lighter teal)
            "#f5ebd6", -- bright white (very light cream)
        },

        -- Melange tab bar colors
        tab_bar = {
            background = "#2d2721", -- Melange dark background
            active_tab = {
                bg_color = "#d47d49", -- Melange warm orange
                fg_color = "#2d2721", -- Dark text for contrast
                intensity = "Bold",
            },
            inactive_tab = {
                bg_color = "#4f4135", -- Melange medium brown
                fg_color = "#ede0c8", -- Much lighter beige text
            },
            inactive_tab_hover = {
                bg_color = "#726450", -- Melange darker brown
                fg_color = "#f5ebd6", -- Very light cream on hover
            },
            new_tab = {
                bg_color = "#4f4135", -- Melange medium brown
                fg_color = "#99936d", -- Melange warm green button
            },
            new_tab_hover = {
                bg_color = "#726450", -- Melange darker brown
                fg_color = "#a9a674", -- Brighter green on hover
            },
        },
    }
end

-- Function to get current SSH hostname from prompt (original function, kept for compatibility)
local function get_current_ssh_host(window)
    local pane = window:active_pane()
    local text = pane:get_lines_as_text()
    local lines = wezterm.split_by_newlines(text)
    local last_line = lines[#lines]
    -- Look for a pattern like "user@hostname:" in the prompt
    local hostname = last_line:match('@([^:]+):')
    return hostname
end

-- Function to open a new tab and paste the hostname
local function open_tab_with_hostname(window, pane, hostname)
    if hostname then
        window:perform_action(
            wezterm.action.SpawnCommandInNewTab {
                args = { '/bin/zsh', '-c', 'echo "' .. hostname .. '"; zsh' },
            },
            pane
        )
    else
        wezterm.log_info("No SSH hostname detected in the current prompt")
    end
end

-- Event handler for the custom action
wezterm.on('user-var-changed', function(window, pane, name, value)
    if name == "open_tab_with_hostname" then
        local hostname = get_current_ssh_host(window)
        open_tab_with_hostname(window, pane, hostname)
    end
end)

-- Key Bindings
config.keys = {
    { key = "t", mods = "CTRL|SHIFT", action = wezterm.action { SpawnTab = "CurrentPaneDomain" } },
    { key = "w", mods = "CTRL|SHIFT", action = wezterm.action { CloseCurrentPane = { confirm = true } } },
    { key = "h", mods = "CTRL|SHIFT", action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain" } } },
    { key = "v", mods = "CTRL|SHIFT", action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain" } } },

    -- Existing key binding for opening a new tab with hostname
    { key = "i", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent 'open_tab_with_hostname' },

    -- Existing termscp binding
    {
        key = "k",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(win, pane)
            -- Open a new tab
            win:perform_action(wezterm.action.SpawnTab("CurrentPaneDomain"), pane)
            -- Send the hostname command to the new tab
            win:perform_action(wezterm.action.SendString("termscp lab1010:22:/ -P 123456\n"), win:active_pane())
        end),
    },

    -- NEW: Open Cyberduck SCP session to current SSH host (using our module)
    {
        key = "c",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(win, pane)
            cyberduck_ssh.open_cyberduck_scp(win, pane)
        end),
    },

    -- DEBUG: Test Cyberduck with debug logging
    {
        key = "d",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(win, pane)
            cyberduck_debug.open_cyberduck_debug(win, pane)
        end),
    },
    
    -- SSH Launcher: Open SSH server selection menu
    {
        key = "s",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(win, pane)
            wezterm.log_info("SSH Launcher key binding triggered!")
            ssh_launcher.show_ssh_launcher(win, pane)
        end),
    },
    
    -- Test key binding
    {
        key = "l",
        mods = "CTRL|SHIFT",
        action = wezterm.action.ShowLauncher,
    },
}

-- Default Shell
config.default_prog = { "/bin/zsh", "-l" }

return config

