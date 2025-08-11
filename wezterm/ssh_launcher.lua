local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function get_servers_file_path()
    return wezterm.config_dir .. "/servers.json"
end

local function load_servers()
    local servers_file = get_servers_file_path()
    local f = io.open(servers_file, "r")
    if not f then
        return {}
    end
    
    local content = f:read("*a")
    f:close()
    
    if content == "" then
        return {}
    end
    
    local ok, servers = pcall(wezterm.json_parse, content)
    if not ok then
        return {}
    end
    
    return servers or {}
end

local function save_servers(servers)
    local servers_file = get_servers_file_path()
    local ok, json_content = pcall(wezterm.json_encode, servers)
    if not ok then
        return false
    end
    
    local f = io.open(servers_file, "w")
    if not f then
        return false
    end
    
    f:write(json_content)
    f:close()
    return true
end

-- Store password in macOS Keychain
local function store_password_in_keychain(server_name, password)
    local service = "wezterm-ssh-" .. server_name
    local account = "password"
    
    -- Delete existing password if any
    os.execute(string.format(
        "security delete-generic-password -s '%s' -a '%s' 2>/dev/null",
        service, account
    ))
    
    -- Escape password for shell
    local escaped_password = password:gsub("'", "'\"'\"'")
    
    -- Add new password
    local cmd = string.format(
        "security add-generic-password -s '%s' -a '%s' -w '%s'",
        service, account, escaped_password
    )
    
    local result = os.execute(cmd)
    return result == 0
end

-- Retrieve password from macOS Keychain
local function get_password_from_keychain(server_name)
    local service = "wezterm-ssh-" .. server_name
    local account = "password"
    
    local handle = io.popen(string.format(
        "security find-generic-password -s '%s' -a '%s' -w 2>/dev/null",
        service, account
    ))
    
    if handle then
        local password = handle:read("*a")
        handle:close()
        if password then
            password = password:gsub("%s+$", "")
            if password ~= "" then
                return password
            end
        end
    end
    return nil
end

function M.show_ssh_launcher(window, pane)
    -- Always load fresh servers list
    local servers = load_servers()
    local choices = {}
    
    -- Add menu options
    table.insert(choices, { id = "add_with_password", label = "➕ Add New Server" })
    
    if #servers > 0 then
        table.insert(choices, { id = "edit", label = "✏️  Edit Server" })
        table.insert(choices, { id = "delete", label = "🗑️  Delete Server" })
    end
    
    table.insert(choices, { id = "sep", label = "──────────────────────────" })
    
    -- Add servers to menu
    if #servers == 0 then
        table.insert(choices, { id = "empty", label = "📭 No servers configured" })
    else
        for i, server in ipairs(servers) do
            local auth_indicator = ""
            if server.identity_file then
                auth_indicator = " 🔑"
            elseif get_password_from_keychain(server.name) then
                auth_indicator = " 🔐"
            end
            
            local label = string.format("🖥️  %s [%s@%s:%d]%s", 
                server.name, 
                server.user or "root", 
                server.host, 
                server.port or 22,
                auth_indicator
            )
            table.insert(choices, { id = "server_" .. i, label = label })
        end
    end
    
    window:perform_action(
        act.InputSelector {
            title = "🌐 SSH Server Launcher",
            choices = choices,
            fuzzy = true,
            action = wezterm.action_callback(function(window, pane, id, label)
                if not id then return end
                
                if id == "add_with_password" then
                    window:perform_action(
                        act.PromptInputLine {
                            description = "Enter: ServerName,Host,User,Password (e.g., MyServer,192.168.1.1,root,mypassword):",
                            action = wezterm.action_callback(function(window, pane, line)
                                if not line or line == "" then 
                                    M.show_ssh_launcher(window, pane)
                                    return 
                                end
                                
                                local parts = {}
                                for part in string.gmatch(line, "([^,]+)") do
                                    table.insert(parts, part:match("^%s*(.-)%s*$"))
                                end
                                
                                if #parts < 4 then
                                    window:toast_notification("SSH Launcher", "Need: name,host,user,password (minimum)", nil, 2000)
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
                                local new_server = {
                                    name = parts[1],
                                    host = parts[2],
                                    user = parts[3] or "root",
                                    port = tonumber(parts[5]) or 22, -- Port is always 22 unless specified as 5th parameter
                                }
                                local password = parts[4] -- Password is always 4th parameter
                                
                                local servers = load_servers()
                                table.insert(servers, new_server)
                                
                                if save_servers(servers) then
                                    -- Store password in keychain
                                    if store_password_in_keychain(new_server.name, password) then
                                        window:toast_notification("SSH Launcher", 
                                            "Added: " .. new_server.name .. " (with password)", nil, 2000)
                                    else
                                        window:toast_notification("SSH Launcher", 
                                            "Server added but failed to save password", nil, 2000)
                                    end
                                else
                                    window:toast_notification("SSH Launcher", "Failed to save server!", nil, 2000)
                                end
                                
                                -- Launcher exits after adding server (consistent with connection behavior)
                            end)
                        },
                        pane
                    )
                    
                elseif id == "edit" then
                    -- Show server list for editing
                    local edit_choices = {}
                    for i, server in ipairs(servers) do
                        local has_pwd = get_password_from_keychain(server.name) and " 🔐" or ""
                        table.insert(edit_choices, {
                            id = tostring(i),
                            label = "✏️  " .. server.name .. " [" .. server.user .. "@" .. server.host .. ":" .. server.port .. "]" .. has_pwd,
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select server to edit:",
                            choices = edit_choices,
                            action = wezterm.action_callback(function(window, pane, srv_id)
                                if srv_id then
                                    local idx = tonumber(srv_id)
                                    if idx and servers[idx] then
                                        local server = servers[idx]
                                        local current_password = get_password_from_keychain(server.name) or ""
                                        local current_values = string.format("%s,%s,%s,%s,%d", 
                                            server.name, server.host, server.user, current_password, server.port)
                                        
                                        window:perform_action(
                                            act.PromptInputLine {
                                                description = "Edit: ServerName,Host,User,Password (Port optional as 5th param):",
                                                action = wezterm.action_callback(function(window, pane, line)
                                                    if not line or line == "" then
                                                        M.show_ssh_launcher(window, pane)
                                                        return
                                                    end
                                                    
                                                    local parts = {}
                                                    for part in string.gmatch(line, "([^,]+)") do
                                                        table.insert(parts, part:match("^%s*(.-)%s*$"))
                                                    end
                                                    
                                                    if #parts < 4 then
                                                        window:toast_notification("SSH Launcher", "Need: name,host,user,password (minimum)", nil, 2000)
                                                        M.show_ssh_launcher(window, pane)
                                                        return
                                                    end
                                                    
                                                    -- Delete old password from keychain
                                                    os.execute(string.format(
                                                        "security delete-generic-password -s 'wezterm-ssh-%s' -a 'password' 2>/dev/null",
                                                        server.name
                                                    ))
                                                    
                                                    -- Update server
                                                    servers[idx] = {
                                                        name = parts[1],
                                                        host = parts[2],
                                                        user = parts[3],
                                                        port = tonumber(parts[5]) or 22,
                                                    }
                                                    local password = parts[4]
                                                    
                                                    if save_servers(servers) then
                                                        -- Store new password
                                                        if password and password ~= "" then
                                                            if store_password_in_keychain(servers[idx].name, password) then
                                                                window:toast_notification("SSH Launcher", 
                                                                    "Updated: " .. servers[idx].name, nil, 2000)
                                                            else
                                                                window:toast_notification("SSH Launcher", 
                                                                    "Server updated but failed to save password", nil, 2000)
                                                            end
                                                        else
                                                            window:toast_notification("SSH Launcher", 
                                                                "Updated: " .. servers[idx].name .. " (no password)", nil, 2000)
                                                        end
                                                    else
                                                        window:toast_notification("SSH Launcher", "Failed to update server!", nil, 2000)
                                                    end
                                                    
                                                    -- Launcher exits after editing server (consistent behavior)
                                                end)
                                            },
                                            pane
                                        )
                                    end
                                else
                                    -- User cancelled edit, exit launcher
                                end
                            end)
                        },
                        pane
                    )
                    
                elseif id == "delete" then
                    local del_choices = {}
                    for i, server in ipairs(servers) do
                        table.insert(del_choices, {
                            id = tostring(i),
                            label = "❌ " .. server.name,
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select server to delete:",
                            choices = del_choices,
                            action = wezterm.action_callback(function(window, pane, del_id)
                                if del_id then
                                    local idx = tonumber(del_id)
                                    if idx and servers[idx] then
                                        local deleted_name = servers[idx].name
                                        table.remove(servers, idx)
                                        save_servers(servers)
                                        -- Delete password too
                                        os.execute(string.format(
                                            "security delete-generic-password -s 'wezterm-ssh-%s' -a 'password' 2>/dev/null",
                                            deleted_name
                                        ))
                                        window:toast_notification("SSH Launcher", "Deleted: " .. deleted_name, nil, 2000)
                                    end
                                end
                                -- Launcher exits after deleting server (consistent behavior)
                            end)
                        },
                        pane
                    )
                    
                elseif id:match("^server_") then
                    -- Connect to server - always reload servers to get latest list
                    local fresh_servers = load_servers()
                    local idx = tonumber(id:match("server_(%d+)"))
                    wezterm.log_info("Attempting to connect to server index " .. idx .. " from " .. #fresh_servers .. " total servers")
                    if idx and idx <= #fresh_servers and fresh_servers[idx] then
                        local server = fresh_servers[idx]
                        wezterm.log_info("Found server: " .. server.name .. " at " .. server.host)
                        local password = get_password_from_keychain(server.name)
                        
                        if password then
                            -- Use sshpass with proper argument separation
                            wezterm.log_info("Connecting with password to: " .. server.name)
                            
                            window:perform_action(
                                act.SpawnCommandInNewTab {
                                    args = { 
                                        "/opt/homebrew/bin/sshpass", 
                                        "-p", password,
                                        "ssh",
                                        "-o", "StrictHostKeyChecking=no",
                                        "-p", tostring(server.port or 22),
                                        server.user .. "@" .. server.host
                                    },
                                },
                                pane
                            )
                            
                            wezterm.log_info("sshpass connection spawned successfully for: " .. server.host)
                            
                            -- Set the tab title after a brief delay
                            wezterm.time.call_after(0.1, function()
                                local mux_tab = window:active_tab()
                                if mux_tab then
                                    mux_tab:set_title(server.host)
                                    wezterm.log_info("Set sshpass tab title to: " .. server.host)
                                else
                                    wezterm.log_error("Failed to get active tab for sshpass title setting")
                                end
                            end)
                        else
                            -- Regular SSH
                            wezterm.log_info("Connecting with regular SSH to: " .. server.name)
                            local ssh_args = { "ssh" }
                            
                            if server.identity_file then
                                table.insert(ssh_args, "-i")
                                table.insert(ssh_args, server.identity_file)
                            end
                            
                            if server.port and server.port ~= 22 then
                                table.insert(ssh_args, "-p")
                                table.insert(ssh_args, tostring(server.port))
                            end
                            
                            table.insert(ssh_args, server.user .. "@" .. server.host)
                            
                            window:perform_action(
                                act.SpawnCommandInNewTab {
                                    args = ssh_args,
                                },
                                pane
                            )
                            
                            wezterm.log_info("SSH connection spawned successfully for: " .. server.host)
                            
                            -- Set the tab title after a brief delay
                            wezterm.time.call_after(0.1, function()
                                local mux_tab = window:active_tab()
                                if mux_tab then
                                    mux_tab:set_title(server.host)
                                    wezterm.log_info("Set SSH tab title to: " .. server.host)
                                else
                                    wezterm.log_error("Failed to get active tab for SSH title setting")
                                end
                            end)
                        end
                    else
                        wezterm.log_error("Server not found at index " .. idx .. " (total servers: " .. #fresh_servers .. ")")
                        window:toast_notification("SSH Launcher", "Server not found at index " .. idx, nil, 2000)
                    end
                end
            end)
        },
        pane
    )
end

return M