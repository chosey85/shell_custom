-- cyberduck_ssh.lua
-- Module for integrating SSH sessions with Cyberduck SCP connections
local wezterm = require("wezterm")

local M = {}

-- Function to normalize and clean up paths
local function normalize_path(path, user)
    if not path or path == '' then
        return ''
    end

    -- Handle tilde expansion
    if path:sub(1, 1) == '~' then
        if path == '~' then
            -- For bare ~, return empty string to let Cyberduck default to SSH server's home directory
            return ''
        else
            -- Convert ~/subpath to just the subpath, letting Cyberduck resolve from home
            local subpath = path:gsub('^~/', '')
            return subpath
        end
    end

    -- Handle absolute paths (already start with /)
    if path:sub(1, 1) == '/' then
        return path
    end

    -- Handle relative paths - convert to absolute by assuming it's relative to home
    -- Examples: "dev" -> "/home/user/dev", "Documents" -> "/home/user/Documents"
    if user then
        return '/home/' .. user .. '/' .. path
    else
        -- Fallback: just make it absolute from root
        return '/' .. path
    end
end

-- Enhanced function to get SSH connection details from terminal prompt
local function get_ssh_connection_details(window)
    local pane = window:active_pane()
    local text = pane:get_lines_as_text()
    local lines = wezterm.split_by_newlines(text)

    -- Check multiple recent lines for SSH connection info
    for i = math.max(1, #lines - 10), #lines do
        local line = lines[i]

        -- Look for patterns like "[user@hostname:~/path]" or "[user@hostname:/path]"
        local user, hostname, path = line:match('%[([^@%s]+)@([^:%s%]]+):([^%]]+)%]')
        if user and hostname and path then
            path = normalize_path(path, user)
            return {
                user = user,
                hostname = hostname,
                path = path,
                port = 22 -- default SSH port
            }
        end

        -- Look for patterns like "[user@hostname path]" (space-separated, no colon)
        user, hostname, path = line:match('%[([^@%s]+)@([^%s%]]+)%s+([^%]]+)%]')
        if user and hostname and path then
            path = normalize_path(path, user)
            return {
                user = user,
                hostname = hostname,
                path = path,
                port = 22 -- default SSH port
            }
        end

        -- Look for standard SSH prompt patterns like "user@hostname:/path$" or "user@hostname:~/path$"
        user, hostname, path = line:match('([^@%s]+)@([^:%s]+):([^%s%$]+)')
        if user and hostname and path then
            path = normalize_path(path, user)
            return {
                user = user,
                hostname = hostname,
                path = path,
                port = 22 -- default SSH port
            }
        end

        -- Look for patterns like "[user@hostname" without path info
        user, hostname = line:match('%[([^@%s]+)@([^:%s%]]+)')
        if user and hostname then
            return {
                user = user,
                hostname = hostname,
                path = '', -- no path detected
                port = 22  -- default SSH port
            }
        end

        -- Look for patterns like "user@hostname:" (without square bracket, no path)
        user, hostname = line:match('([^@%s%[]+)@([^:%s%]]+):')
        if user and hostname then
            return {
                user = user,
                hostname = hostname,
                path = '', -- no path detected in this format
                port = 22  -- default SSH port
            }
        end

        -- Alternative pattern for just hostname (when username detection fails)
        local just_hostname = line:match('@([^:%s%]]+):')
        if just_hostname then
            return {
                user = nil, -- will use default user
                hostname = just_hostname,
                path = '',  -- no path detected
                port = 22
            }
        end
    end

    return nil
end

-- Main function to open Cyberduck with SCP connection to current SSH host
function M.open_cyberduck_scp(window, pane)
    local ssh_details = get_ssh_connection_details(window)

    if not ssh_details then
        wezterm.log_info("No SSH connection detected in current session")
        return false
    end

    local hostname = ssh_details.hostname
    local user = ssh_details.user or os.getenv("USER") or "user"
    local port = ssh_details.port or 22

    -- Always open at root directory for simplicity and consistency
    local cyberduck_url = string.format("sftp://%s@%s:%d/", user, hostname, port)

    -- Force open with Cyberduck specifically
    local success = os.execute(string.format('open -a "Cyberduck" "%s"', cyberduck_url))

    if success then
        wezterm.log_info(string.format("Opening Cyberduck SCP session to %s@%s:%d/", user, hostname, port))
        return true
    else
        wezterm.log_error("Failed to open Cyberduck. Make sure Cyberduck is installed.")
        return false
    end
end

-- Alternative method using direct Cyberduck executable (for troubleshooting)
function M.open_cyberduck_direct(window, pane)
    local ssh_details = get_ssh_connection_details(window)

    if not ssh_details then
        wezterm.log_info("No SSH connection detected in current session")
        return false
    end

    local hostname = ssh_details.hostname
    local user = ssh_details.user or os.getenv("USER") or "user"
    local port = ssh_details.port or 22

    -- Always open at root directory
    local cyberduck_url = string.format("sftp://%s@%s:%d/", user, hostname, port)

    -- Launch Cyberduck directly
    local success = os.execute(string.format('"/Applications/Cyberduck.app/Contents/MacOS/Cyberduck" "%s" &',
        cyberduck_url))

    if success then
        wezterm.log_info(string.format("Opening Cyberduck directly to %s@%s:%d/", user, hostname, port))
        return true
    else
        wezterm.log_error("Failed to launch Cyberduck directly.")
        return false
    end
end

-- Function to get current SSH details (for debugging/testing)
function M.get_ssh_info(window)
    return get_ssh_connection_details(window)
end

return M
