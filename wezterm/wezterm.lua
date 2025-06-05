local wezterm = require("wezterm")
local cyberduck_ssh = require("cyberduck_ssh") -- Import our cyberduck module

local config = wezterm.config_builder()

-- General Settings
config.automatically_reload_config = true
config.enable_tab_bar = true
config.use_fancy_tab_bar = true -- Switch back to fancy tab bar for better styling
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE | RESIZE"
config.default_cursor_style = "BlinkingBar"
config.color_scheme = "Pastel White (terminal.sexy)"

-- Font Settings
config.font = wezterm.font("JetBrains Mono", {
    weight = "DemiBold",
})
config.font_size = 12.5

-- Window Padding
config.window_padding = {
    left = "3cell",
    right = "3cell",
    top = "0cell",
    bottom = "0cell",
}

-- Background Opacity
config.window_background_opacity = 0.8

-- Cursor Customization
config.cursor_blink_rate = 800
config.cursor_thickness = "0.1cell"

-- Tab Bar Customization: Using fancy tab bar with custom styling
config.tab_max_width = 35
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = true
config.show_new_tab_button_in_tab_bar = true

-- Custom tab title formatting for fancy tabs
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local process = string.gsub(tab.active_pane.foreground_process_name or '', '(.*[/\\])(.*)', '%2')
    local title = tab.active_pane.title

    -- Add process-specific prefixes
    local prefixes = {
        ['ssh'] = '🌐 ',
        ['nvim'] = '📝 ',
        ['vim'] = '📝 ',
        ['node'] = '⚡ ',
        ['python'] = '🐍 ',
        ['git'] = '📋 ',
        ['cargo'] = '🦀 ',
        ['docker'] = '🐳 ',
    }

    local prefix = prefixes[process] or '💻 '
    local display_title = prefix .. process

    -- Truncate if needed
    if #display_title > max_width - 4 then
        display_title = display_title:sub(1, max_width - 7) .. '...'
    end

    return display_title
end)

-- Enhanced status line
wezterm.on('update-right-status', function(window, pane)
    local date_time = wezterm.strftime '%d-%m-%Y %H:%M:%S'

    window:set_right_status(wezterm.format {
        { Foreground = { Color = '#8fbc8f' } }, -- Olive green to match tabs
        { Text = '📅 ' .. date_time .. ' ' },
    })
end)

-- Color Settings - Olive green theme
config.colors = {
    foreground = "#B5B5B5",
    background = "black",
    cursor_bg = "#00FF00",
    cursor_fg = "black",
    cursor_border = "#00FF00",
    selection_bg = "#44475a",
    selection_fg = "black",

    -- Olive green tab bar colors
    tab_bar = {
        background = "#1a1a1a",

        active_tab = {
            bg_color = "#8fbc8f", -- Olive green (dark sea green)
            fg_color = "#1a1a1a", -- Dark text for contrast
            intensity = "Bold",
        },

        inactive_tab = {
            bg_color = "#2d2d2d", -- Dark gray
            fg_color = "#cccccc", -- Light gray text
        },

        inactive_tab_hover = {
            bg_color = "#404040", -- Lighter gray on hover
            fg_color = "#ffffff", -- White on hover
        },

        new_tab = {
            bg_color = "#2d2d2d",
            fg_color = "#8fbc8f", -- Olive green + button
        },

        new_tab_hover = {
            bg_color = "#404040",
            fg_color = "#a3d977", -- Lighter green on hover
        },
    },
}

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

    -- OPTIONAL: Alternative Cyberduck method (uncomment if needed for troubleshooting)
    -- {
    --     key = "c",
    --     mods = "CTRL|ALT|SHIFT",
    --     action = wezterm.action_callback(function(win, pane)
    --         cyberduck_ssh.open_cyberduck_direct(win, pane)
    --     end),
    -- },
}

-- General Settings
config.automatically_reload_config = true
config.enable_tab_bar = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE | RESIZE"
config.default_cursor_style = "BlinkingBar"
config.color_scheme = "Pastel White (terminal.sexy)"
config.use_fancy_tab_bar = true

-- Default Shell
config.default_prog = { "/bin/zsh", "-l" }

return config
