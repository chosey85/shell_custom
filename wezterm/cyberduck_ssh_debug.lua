-- cyberduck_ssh_debug.lua
-- Debug version of the cyberduck module
local wezterm = require("wezterm")

local M = {}

-- Function to get SSH connection details with verbose debugging
local function get_ssh_connection_details_debug(window)
    local pane = window:active_pane()
    local text = pane:get_lines_as_text()
    local lines = wezterm.split_by_newlines(text)

    -- Log all recent lines for debugging
    wezterm.log_info("=== DEBUG: Recent terminal lines ===")
    for i = math.max(1, #lines - 5), #lines do
        if lines[i] and lines[i] ~= "" then
            wezterm.log_info(string.format("Line %d: '%s'", i, lines[i]))
        end
    end

    -- Check multiple recent lines for SSH connection info
    for i = math.max(1, #lines - 10), #lines do
        local line = lines[i]
        if not line or line == "" then
            goto continue
        end

        -- Look for patterns like "[user@hostname:~/path]" or "[user@hostname:/path]"
        local user, hostname, path = line:match('%[([^@%s]+)@([^:%s%]]+):([^%]]+)%]')
        if user and hostname and path then
            wezterm.log_info(string.format("Found SSH pattern 1: user=%s, hostname=%s, path=%s", user, hostname, path))
            return {
                user = user,
                hostname = hostname,
                path = path,
                port = 22
            }
        end

        -- Look for standard SSH prompt patterns like "user@hostname:/path$" or "user@hostname:~/path$"
        user, hostname, path = line:match('([^@%s]+)@([^:%s]+):([^%s%$]+)')
        if user and hostname and path then
            wezterm.log_info(string.format("Found SSH pattern 2: user=%s, hostname=%s, path=%s", user, hostname, path))
            return {
                user = user,
                hostname = hostname,
                path = path,
                port = 22
            }
        end

        -- Look for patterns like "user@hostname:" (without path)
        user, hostname = line:match('([^@%s%[]+)@([^:%s%]]+):')
        if user and hostname then
            wezterm.log_info(string.format("Found SSH pattern 3: user=%s, hostname=%s", user, hostname))
            return {
                user = user,
                hostname = hostname,
                path = '',
                port = 22
            }
        end

        ::continue::
    end

    wezterm.log_info("No SSH connection pattern found")
    return nil
end

-- Debug function to open Cyberduck
function M.open_cyberduck_debug(window, pane)
    wezterm.log_info("=== CYBERDUCK DEBUG: Function called ===")
    
    local ssh_details = get_ssh_connection_details_debug(window)

    if not ssh_details then
        wezterm.log_info("DEBUG: No SSH connection detected")
        -- Try a manual fallback
        local cyberduck_url = "sftp://pliops@pl-labnirr-vnc01:22/"
        wezterm.log_info(string.format("DEBUG: Trying manual fallback URL: %s", cyberduck_url))
        local success = os.execute(string.format('open -a "Cyberduck" "%s"', cyberduck_url))
        if success then
            wezterm.log_info("DEBUG: Manual fallback succeeded")
        else
            wezterm.log_info("DEBUG: Manual fallback failed")
        end
        return false
    end

    local hostname = ssh_details.hostname
    local user = ssh_details.user or os.getenv("USER") or "user"
    local port = ssh_details.port or 22

    local cyberduck_url = string.format("sftp://%s@%s:%d/", user, hostname, port)
    wezterm.log_info(string.format("DEBUG: Opening Cyberduck with URL: %s", cyberduck_url))

    local success = os.execute(string.format('open -a "Cyberduck" "%s"', cyberduck_url))

    if success then
        wezterm.log_info("DEBUG: Cyberduck command succeeded")
        return true
    else
        wezterm.log_info("DEBUG: Cyberduck command failed")
        return false
    end
end

return M
