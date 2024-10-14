local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- General Settings
config.automatically_reload_config = true
config.enable_tab_bar = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "TITLE | RESIZE"
config.default_cursor_style = "BlinkingBar"
config.color_scheme = "Pastel White (terminal.sexy)"
config.use_fancy_tab_bar = true

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

-- Tab Bar Customization: Wider Tabs and Fancy Appearance
config.tab_max_width = 40

-- Color Settings
config.colors = {
    foreground = "#B5B5B5",
    background = "black",
    cursor_bg = "#00FF00",
    cursor_fg = "black",
    cursor_border = "#00FF00",
    selection_bg = "#44475a",
    selection_fg = "black",
    tab_bar = {
        background = "black",
        active_tab = {
            bg_color = "#4c566a",
            fg_color = "#d8dee9",
        },
        inactive_tab = {
            bg_color = "#3b4252",
            fg_color = "#d8dee9",
        },
    },
}

-- Function to get current SSH hostname from prompt
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

    -- New key binding for opening a new tab with hostname
    { key = "i", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent 'open_tab_with_hostname' },
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
}

-- Default Shell
config.default_prog = { "/bin/zsh", "-l" }

return config
