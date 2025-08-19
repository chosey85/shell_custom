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

-- Simple folder support functions
local function load_folders()
    local folders_file = wezterm.config_dir .. "/folders.json"
    local f = io.open(folders_file, "r")
    if not f then
        return {{ id = "root", name = "Root", parent = nil }}
    end
    
    local content = f:read("*a")
    f:close()
    
    if content == "" then
        return {{ id = "root", name = "Root", parent = nil }}
    end
    
    local ok, folders = pcall(wezterm.json_parse, content)
    if ok and folders then
        return folders
    else
        return {{ id = "root", name = "Root", parent = nil }}
    end
end

local function get_folder_name(folders, folder_id)
    for _, folder in ipairs(folders) do
        if folder.id == folder_id then
            return folder.name
        end
    end
    return "Root"
end

-- Navigation state tracking
local navigation_level = "main" -- "main", "folder_view", "edit", "delete", etc.

-- Show folder selector and call callback with selected folder_id
local function show_folder_selector(window, pane, folders, title, callback)
    local folder_choices = {}
    table.insert(folder_choices, { id = "root", label = "📁 Root" })
    
    for _, folder in ipairs(folders) do
        if folder.id ~= "root" then
            table.insert(folder_choices, {
                id = folder.id,
                label = "📁 " .. folder.name
            })
        end
    end
    
    window:perform_action(
        act.InputSelector {
            title = title .. " - Press Esc to go back",
            choices = folder_choices,
            fuzzy = true,
            action = wezterm.action_callback(function(window, pane, folder_id, label)
                if not folder_id then
                    -- Handle Esc key - go back to main menu
                    navigation_level = "main"
                    M.show_ssh_launcher(window, pane)
                    return
                end
                
                if folder_id then
                    callback(folder_id)
                end
            end)
        },
        pane
    )
end

-- Show servers in a specific folder
local function show_folder_view(window, pane, folder_id)
    navigation_level = "folder_view"
    local servers = load_servers()
    local folders = load_folders()
    local folder_name = get_folder_name(folders, folder_id)
    
    local choices = {}
    
    -- Add back navigation
    table.insert(choices, { id = "back", label = "⬅️ Back to Main View" })
    table.insert(choices, { id = "sep", label = "──────────────────────────" })
    
    -- Filter servers by folder
    local folder_servers = {}
    for i, server in ipairs(servers) do
        if (server.folder_id or "root") == folder_id then
            table.insert(folder_servers, {server = server, index = i})
        end
    end
    
    if #folder_servers == 0 then
        table.insert(choices, { id = "empty", label = "📭 No servers in this folder" })
    else
        for _, server_info in ipairs(folder_servers) do
            local server = server_info.server
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
            table.insert(choices, { id = "server_" .. server_info.index, label = label })
        end
    end
    
    window:perform_action(
        act.InputSelector {
            title = "📁 " .. folder_name .. " (" .. #folder_servers .. " servers) - Press Esc to go back",
            choices = choices,
            fuzzy = true,
            action = wezterm.action_callback(function(window, pane, id, label)
                if not id then 
                    -- Handle Esc key - go back to main menu
                    navigation_level = "main"
                    M.show_ssh_launcher(window, pane)
                    return
                end
                
                if id == "back" then
                    navigation_level = "main"
                    M.show_ssh_launcher(window, pane)
                    return
                elseif id:match("^server_") then
                    -- Connect to server - reuse existing connection logic
                    local fresh_servers = load_servers()
                    local idx = tonumber(id:match("server_(%d+)"))
                    
                    if idx and idx <= #fresh_servers and fresh_servers[idx] then
                        local server = fresh_servers[idx]
                        local password = get_password_from_keychain(server.name)
                        
                        if password then
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
                            
                            wezterm.time.call_after(0.1, function()
                                local mux_tab = window:active_tab()
                                if mux_tab then
                                    mux_tab:set_title(server.host)
                                end
                            end)
                        else
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
                            
                            wezterm.time.call_after(0.1, function()
                                local mux_tab = window:active_tab()
                                if mux_tab then
                                    mux_tab:set_title(server.host)
                                end
                            end)
                        end
                    end
                end
            end)
        },
        pane
    )
end

function M.show_ssh_launcher(window, pane)
    navigation_level = "main"
    -- Always load fresh servers list
    local servers = load_servers()
    local folders = load_folders()
    local choices = {}
    
    -- Add menu options
    table.insert(choices, { id = "add_with_password", label = "➕ Add New Server" })
    
    if #servers > 0 then
        table.insert(choices, { id = "edit", label = "✏️  Edit Server" })
        table.insert(choices, { id = "delete", label = "🗑️  Delete Server" })
    end
    
    table.insert(choices, { id = "create_folder", label = "📁 Create New Folder" })
    
    if #folders > 1 then -- More than just root
        table.insert(choices, { id = "rename_folder", label = "📝 Rename Folder" })
        table.insert(choices, { id = "delete_folder", label = "🗑️  Delete Empty Folder" })
    end
    
    table.insert(choices, { id = "sep", label = "──────────────────────────" })
    
    -- Add servers to menu (grouped by folders)
    if #servers == 0 then
        table.insert(choices, { id = "empty", label = "📭 No servers configured" })
    else
        -- Group servers by folder
        local servers_by_folder = {}
        for i, server in ipairs(servers) do
            local folder_id = server.folder_id or "root"
            if not servers_by_folder[folder_id] then
                servers_by_folder[folder_id] = {}
            end
            table.insert(servers_by_folder[folder_id], {server = server, index = i})
        end
        
        -- Display root servers first
        if servers_by_folder["root"] then
            for _, server_info in ipairs(servers_by_folder["root"]) do
                local server = server_info.server
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
                table.insert(choices, { id = "server_" .. server_info.index, label = label })
            end
        end
        
        -- Display servers grouped by folders
        for _, folder in ipairs(folders) do
            if folder.id ~= "root" and servers_by_folder[folder.id] then
                -- Add folder header (clickable)
                table.insert(choices, { 
                    id = "folder_view_" .. folder.id, 
                    label = "📁 " .. folder.name .. " (" .. #servers_by_folder[folder.id] .. " servers)"
                })
                
                -- Add servers in this folder (indented)
                for _, server_info in ipairs(servers_by_folder[folder.id]) do
                    local server = server_info.server
                    local auth_indicator = ""
                    if server.identity_file then
                        auth_indicator = " 🔑"
                    elseif get_password_from_keychain(server.name) then
                        auth_indicator = " 🔐"
                    end
                    
                    local label = string.format("  🖥️  %s [%s@%s:%d]%s", 
                        server.name, 
                        server.user or "root", 
                        server.host, 
                        server.port or 22,
                        auth_indicator
                    )
                    table.insert(choices, { id = "server_" .. server_info.index, label = label })
                end
            end
        end
    end
    
    window:perform_action(
        act.InputSelector {
            title = "🌐 SSH Server Launcher",
            choices = choices,
            fuzzy = true,
            action = wezterm.action_callback(function(window, pane, id, label)
                if not id then 
                    -- Handle Esc key - only exit to terminal if in main menu
                    if navigation_level == "main" then
                        return -- This will exit to terminal
                    else
                        -- Navigate back to main menu from sub-menus
                        navigation_level = "main"
                        M.show_ssh_launcher(window, pane)
                        return
                    end
                end
                
                -- Handle folder view clicks (keep for backward compatibility)
                if id:match("^folder_view_") then
                    local folder_id = id:match("^folder_view_(.+)")
                    show_folder_view(window, pane, folder_id)
                    return
                end
                
                if id == "create_folder" then
                    window:perform_action(
                        act.PromptInputLine {
                            description = "Enter folder name:",
                            action = wezterm.action_callback(function(window, pane, name)
                                if not name or name == "" then
                                    return
                                end
                                
                                local folders = load_folders()
                                local new_folder = {
                                    id = "folder_" .. os.time() .. "_" .. math.random(1000, 9999),
                                    name = name,
                                    parent = "root"
                                }
                                
                                table.insert(folders, new_folder)
                                
                                local folders_file = wezterm.config_dir .. "/folders.json"
                                local ok, json_content = pcall(wezterm.json_encode, folders)
                                if ok then
                                    local f = io.open(folders_file, "w")
                                    if f then
                                        f:write(json_content)
                                        f:close()
                                        wezterm.log_info("Created folder: " .. name)
                                    end
                                end
                            end)
                        },
                        pane
                    )
                    
                elseif id == "rename_folder" then
                    navigation_level = "rename_folder"
                    -- Show folder list for renaming (exclude root)
                    local rename_choices = {}
                    for _, folder in ipairs(folders) do
                        if folder.id ~= "root" then
                            table.insert(rename_choices, {
                                id = folder.id,
                                label = "📝 " .. folder.name
                            })
                        end
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select folder to rename - Press Esc to go back:",
                            choices = rename_choices,
                            fuzzy = true,
                            action = wezterm.action_callback(function(window, pane, folder_id)
                                if not folder_id then
                                    -- Handle Esc key - go back to main menu
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
                                if folder_id then
                                    local folder_name = get_folder_name(folders, folder_id)
                                    window:perform_action(
                                        act.PromptInputLine {
                                            description = "Enter new name for '" .. folder_name .. "':",
                                            action = wezterm.action_callback(function(window, pane, new_name)
                                                if not new_name or new_name == "" then
                                                    navigation_level = "main"
                                                    M.show_ssh_launcher(window, pane)
                                                    return
                                                end
                                                
                                                -- Update folder name
                                                for i, folder in ipairs(folders) do
                                                    if folder.id == folder_id then
                                                        folders[i].name = new_name
                                                        break
                                                    end
                                                end
                                                
                                                -- Save folders
                                                local folders_file = wezterm.config_dir .. "/folders.json"
                                                local ok, json_content = pcall(wezterm.json_encode, folders)
                                                if ok then
                                                    local f = io.open(folders_file, "w")
                                                    if f then
                                                        f:write(json_content)
                                                        f:close()
                                                        wezterm.log_info("Renamed folder to: " .. new_name)
                                                    end
                                                end
                                                
                                                navigation_level = "main"
                                                M.show_ssh_launcher(window, pane)
                                            end)
                                        },
                                        pane
                                    )
                                end
                            end)
                        },
                        pane
                    )
                    
                elseif id == "delete_folder" then
                    navigation_level = "delete_folder"
                    -- Show folder list for deletion (exclude root and non-empty folders)
                    local delete_choices = {}
                    for _, folder in ipairs(folders) do
                        if folder.id ~= "root" then
                            -- Check if folder is empty
                            local has_servers = false
                            for _, server in ipairs(servers) do
                                if server.folder_id == folder.id then
                                    has_servers = true
                                    break
                                end
                            end
                            
                            if not has_servers then
                                table.insert(delete_choices, {
                                    id = folder.id,
                                    label = "🗑️  " .. folder.name .. " (empty)"
                                })
                            end
                        end
                    end
                    
                    if #delete_choices == 0 then
                        table.insert(delete_choices, {
                            id = "no_empty",
                            label = "📭 No empty folders to delete"
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select empty folder to delete - Press Esc to go back:",
                            choices = delete_choices,
                            fuzzy = true,
                            action = wezterm.action_callback(function(window, pane, folder_id)
                                if not folder_id then
                                    -- Handle Esc key - go back to main menu
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
                                if folder_id == "no_empty" then
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
                                if folder_id then
                                    local folder_name = get_folder_name(folders, folder_id)
                                    
                                    -- Remove folder from folders list
                                    for i, folder in ipairs(folders) do
                                        if folder.id == folder_id then
                                            table.remove(folders, i)
                                            break
                                        end
                                    end
                                    
                                    -- Save folders
                                    local folders_file = wezterm.config_dir .. "/folders.json"
                                    local ok, json_content = pcall(wezterm.json_encode, folders)
                                    if ok then
                                        local f = io.open(folders_file, "w")
                                        if f then
                                            f:write(json_content)
                                            f:close()
                                            wezterm.log_info("Deleted folder: " .. folder_name)
                                        end
                                    end
                                    
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                end
                            end)
                        },
                        pane
                    )
                    
                elseif id == "move_server" then
                    -- First select which server to move
                    local server_choices = {}
                    for i, server in ipairs(servers) do
                        local folder_name = get_folder_name(folders, server.folder_id or "root")
                        table.insert(server_choices, {
                            id = tostring(i),
                            label = server.name .. " (currently in: " .. folder_name .. ")",
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select server to move:",
                            choices = server_choices,
                            fuzzy = true,
                            action = wezterm.action_callback(function(window, pane, srv_id)
                                if srv_id then
                                    local server_idx = tonumber(srv_id)
                                    if server_idx and servers[server_idx] then
                                        -- Now select which folder to move to
                                        local folder_choices = {}
                                        table.insert(folder_choices, { id = "root", label = "📁 Root" })
                                        
                                        for _, folder in ipairs(folders) do
                                            if folder.id ~= "root" then
                                                table.insert(folder_choices, {
                                                    id = folder.id,
                                                    label = "📁 " .. folder.name
                                                })
                                            end
                                        end
                                        
                                        window:perform_action(
                                            act.InputSelector {
                                                title = "Move to which folder:",
                                                choices = folder_choices,
                                                fuzzy = true,
                                                action = wezterm.action_callback(function(window, pane, folder_id)
                                                    if folder_id then
                                                        servers[server_idx].folder_id = folder_id
                                                        if save_servers(servers) then
                                                            local folder_name = get_folder_name(folders, folder_id)
                                                            wezterm.log_info("Moved " .. servers[server_idx].name .. " to " .. folder_name)
                                                        end
                                                    end
                                                end)
                                            },
                                            pane
                                        )
                                    end
                                end
                            end)
                        },
                        pane
                    )
                
                -- Connect to server using sshpass
                elseif id:match("^server_") then
                    local fresh_servers = load_servers()
                    local idx = tonumber(id:match("server_(%d+)"))
                    
                    if idx and idx <= #fresh_servers and fresh_servers[idx] then
                        local server = fresh_servers[idx]
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
                    end
                    return
                end
                
                if id == "add_with_password" then
                    -- First, select folder for the new server
                    show_folder_selector(window, pane, folders, "Select folder for new server:", function(folder_id)
                        window:perform_action(
                            act.PromptInputLine {
                                description = "Enter: ServerName,Host,User,Password (e.g., MyServer,192.168.1.1,root,mypassword):",
                                action = wezterm.action_callback(function(window, pane, line)
                                    if not line or line == "" then 
                                        return
                                    end
                                    
                                    local parts = {}
                                    for part in string.gmatch(line, "([^,]+)") do
                                        table.insert(parts, part:match("^%s*(.-)%s*$"))
                                    end
                                    
                                    if #parts < 4 then
                                        return
                                    end
                                    
                                    local new_server = {
                                        name = parts[1],
                                        host = parts[2],
                                        user = parts[3] or "root",
                                        port = tonumber(parts[5]) or 22,
                                        folder_id = folder_id -- Use selected folder
                                    }
                                    local password = parts[4]
                                    
                                    local servers = load_servers()
                                    table.insert(servers, new_server)
                                    
                                    if save_servers(servers) then
                                        -- Store password in keychain
                                        if store_password_in_keychain(new_server.name, password) then
                                            local folder_name = get_folder_name(folders, folder_id)
                                            wezterm.log_info("Added: " .. new_server.name .. " to " .. folder_name)
                                        end
                                    end
                                end)
                            },
                            pane
                        )
                    end)
                    
                elseif id == "edit" then
                    navigation_level = "edit"
                    -- Show server list for editing
                    local edit_choices = {}
                    for i, server in ipairs(servers) do
                        local has_pwd = get_password_from_keychain(server.name) and " 🔐" or ""
                        local folder_name = get_folder_name(folders, server.folder_id or "root")
                        table.insert(edit_choices, {
                            id = tostring(i),
                            label = "✏️  " .. server.name .. " [" .. server.user .. "@" .. server.host .. ":" .. server.port .. "]" .. has_pwd .. " (in " .. folder_name .. ")",
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select server to edit - Press Esc to go back:",
                            choices = edit_choices,
                            fuzzy = true,
                            action = wezterm.action_callback(function(window, pane, srv_id)
                                if not srv_id then
                                    -- Handle Esc key - go back to main menu
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
                                if srv_id then
                                    local idx = tonumber(srv_id)
                                    if idx and servers[idx] then
                                        local server = servers[idx]
                                        
                                        -- Ask what to edit
                                        local edit_options = {
                                            { id = "connection", label = "📝 Edit Connection Details" },
                                            { id = "folder", label = "📁 Change Folder" }
                                        }
                                        
                                        window:perform_action(
                                            act.InputSelector {
                                                title = "What would you like to edit?",
                                                choices = edit_options,
                                                action = wezterm.action_callback(function(window, pane, edit_type)
                                                    if edit_type == "connection" then
                                                        -- Edit connection details
                                                        local current_password = get_password_from_keychain(server.name) or ""
                                                        
                                                        window:perform_action(
                                                            act.PromptInputLine {
                                                                description = "Edit: ServerName,Host,User,Password,Port:",
                                                                action = wezterm.action_callback(function(window, pane, line)
                                                                    if not line or line == "" then
                                                                        return
                                                                    end
                                                                    
                                                                    local parts = {}
                                                                    for part in string.gmatch(line, "([^,]+)") do
                                                                        table.insert(parts, part:match("^%s*(.-)%s*$"))
                                                                    end
                                                                    
                                                                    if #parts < 4 then
                                                                        return
                                                                    end
                                                                    
                                                                    -- Delete old password from keychain
                                                                    os.execute(string.format(
                                                                        "security delete-generic-password -s 'wezterm-ssh-%s' -a 'password' 2>/dev/null",
                                                                        server.name
                                                                    ))
                                                                    
                                                                    -- Update server (keep existing folder)
                                                                    servers[idx] = {
                                                                        name = parts[1],
                                                                        host = parts[2],
                                                                        user = parts[3],
                                                                        port = tonumber(parts[5]) or 22,
                                                                        folder_id = server.folder_id -- Keep current folder
                                                                    }
                                                                    local password = parts[4]
                                                                    
                                                                    if save_servers(servers) then
                                                                        -- Store new password
                                                                        if password and password ~= "" then
                                                                            store_password_in_keychain(servers[idx].name, password)
                                                                        end
                                                                        wezterm.log_info("Updated server: " .. servers[idx].name)
                                                                    end
                                                                end)
                                                            },
                                                            pane
                                                        )
                                                    elseif edit_type == "folder" then
                                                        -- Change folder
                                                        show_folder_selector(window, pane, folders, "Move server to folder:", function(new_folder_id)
                                                            servers[idx].folder_id = new_folder_id
                                                            if save_servers(servers) then
                                                                local folder_name = get_folder_name(folders, new_folder_id)
                                                                wezterm.log_info("Moved " .. server.name .. " to " .. folder_name)
                                                            end
                                                        end)
                                                    end
                                                end)
                                            },
                                            pane
                                        )
                                    end
                                end
                            end)
                        },
                        pane
                    )
                    
                elseif id == "delete" then
                    navigation_level = "delete"
                    local del_choices = {}
                    for i, server in ipairs(servers) do
                        table.insert(del_choices, {
                            id = tostring(i),
                            label = "❌ " .. server.name,
                        })
                    end
                    
                    window:perform_action(
                        act.InputSelector {
                            title = "Select server to delete - Press Esc to go back:",
                            choices = del_choices,
                            action = wezterm.action_callback(function(window, pane, del_id)
                                if not del_id then
                                    -- Handle Esc key - go back to main menu
                                    navigation_level = "main"
                                    M.show_ssh_launcher(window, pane)
                                    return
                                end
                                
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
                    wezterm.log_info("DEBUG: Server ID matched: " .. id)
                    -- Connect to server - always reload servers to get latest list
                    local fresh_servers = load_servers()
                    local idx = tonumber(id:match("server_(%d+)"))
                    wezterm.log_info("DEBUG: Extracted index " .. (idx or "nil") .. " from ID " .. id)
                    wezterm.log_info("DEBUG: Have " .. #fresh_servers .. " total servers")
                    
                    if idx and idx <= #fresh_servers and fresh_servers[idx] then
                        local server = fresh_servers[idx]
                        wezterm.log_info("DEBUG: Found server: " .. server.name)
                        
                        -- Test 1: Just open a new tab with echo
                        wezterm.log_info("DEBUG: Opening test tab")
                        window:perform_action(
                            act.SpawnCommandInNewTab {
                                args = { "echo", "Test connection to " .. server.name },
                            },
                            pane
                        )
                        
                        -- Test 2: Try basic ssh after a delay
                        wezterm.time.call_after(1.0, function()
                            wezterm.log_info("DEBUG: Now trying SSH")
                            window:perform_action(
                                act.SpawnCommandInNewTab {
                                    args = { "ssh", server.user .. "@" .. server.host },
                                },
                                pane
                            )
                        end)
                        
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