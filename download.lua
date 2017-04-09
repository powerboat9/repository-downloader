local rawList = {...}
local list = {}

if #rawList < 1 then
    error("Invalid command syntax", 0)
end

for _, v in ipairs(rawList) do
    if type(v) ~= "string" then
        error("Package name is not a string", 0)
    elseif v:gsub("^!?[%w/:@>-_]*", "") ~= "" then
        error("Invalid package name", 0)
    end
    local removeLua = true
    if v:sub(1, 1) == "!" then
        removeLua = false
    end
    local displayName = (#v > 20) and (v:sub(1, 20) .. "...") or v
    local _, endData, user, repo = v:find("([^/]*)/([^/]*)")
    if not endData then
        error("Invalid package " .. displayName, 0)
    end
    local gitPath, branch, savePath
    if #v > endData then
        v = v:sub(endData + 1, -1)
        local stage = 1
        while true do
            local char = v:sub(1, 1)
            local crop
            if stage <= 1 and char == "@" then
                stage = 2
                _, crop, gitPath = v:find("@([^:>]*)")
            elseif stage <= 2 and char == ":" then
                stage = 3
                _, crop, branch = v:find(":([^>]*)")
            elseif stage <= 3 and char == ">" then
                stage = 4
                _, crop, savePath = v:find(">(.*)")
            else
                error("Malformed package name " .. displayName, 0)
            end
            if stage == 4 or #v == crop then
                break
            else
                v = v:sub(endData + 1, -1)
            end
        end
    end
    list[#list + 1] = {user, repo, savePath, gitPath, branch, removeLua}
end

local function getBaseURL(user, repo, path, branch, removeLua)
    --path = fs.combine(gitPath, path)
    if (path ~= "") and (path:sub(1, 1) ~= "/") then path = "/" .. path end
    return ("https://api.github.com/repos/%s/%s/contents%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch) or "")
end

local function getPathFromURL(url)
    return url:sub(30):gsub("%?ref=.*$", ""):gsub("^[^/]*/[^/]*/contents/?", "")
end

local function getTime()
    return os.time() + os.day() * 24000
end

local function unserializeJSON(str)
    local f = fs.open("k", "w")
    f.write(str)
    f.close()
    local s = str:gsub("\"([^\"]*)\"%s*:%s*", "%1 = "):gsub("%[", "{"):gsub("]", "}"):gsub("null", "nil")
    print(s)
    return textutils.unserialize(s)
end

local function verifyAlphaNumeric(v, err)
    if (type(v) ~= "string") or (v == "") or (v:gsub("%w", "") ~= "") then
        error(err, 0)
    end
end

local function gitGet(user, repo, savePath, gitPath, branch)
    local function verifyAlphaNumeric(str, errorMSG)
        if not (type(user) == "string") or not (user:gsub("[^%w_]+", "") == user) then
            error(errorMSG, 0)
        end
    end
    
    verifyAlphaNumeric(user, "Invalid username")
    verifyAlphaNumeric(repo, "Invalid repository")
    
    savePath = (type(savePath) == "string") and savePath or ("/.APIS/" .. repo)
    
    gitPath = type(gitPath) == "string" and gitPath or ""
    branch = type(branch) == "string" and branch or nil
    
    local downloads = {}
    local function download(url, savePath, isAPICall)
        downloads[url] = {isAPICall = isAPICall, savePath = savePath, gitURL = url}
        http.request(url)
    end
    
    local function save(url, h)
        local fPath = downloads[url].savePath
        fPath = not removeLua and fPath or fPath:gsub("%.lua$", "")
        local file = fs.open(fPath, "w")
        file.write(h.readAll())
        file.close()
        h.close()
    end
    
    local function fail(url, savePath)
        local old = term.getBackgroundColor()
        term.write("Downloading \"")
        local new
        if term.isColor() then new = colors.red else new = colors.grey end
        term.setTextColor(new)
        term.write(url)
        term.setTextColor(old)
        if savePath then
            term.write("\" to \"")
            term.setTextColor(new)
            term.write(savePath)
            term.setTextColor(old)
        end
        term.write("\" failed")
    end
    
    local function filter(url, h)
        local data = unserializeJSON(h.readAll())
        for _, element in ipairs(data) do
            if element.type == "file" then
                download(element.download_url, downloads[url].savePath .. "/" .. element.name, false)
            elseif element.type == "dir" then
                download(element.url, downloads[url].savePath .. "/" .. element.name, true)
            elseif element.type == "symlink" then
                local f = fs.open(downloads[url].savePath .. "/" .. element.name .. ".clnk", "w")
                f.write(element.target:gsub("^/", ""))
                f.close()
            elseif element.type == "submodule" then
                local gitURL, ok = element.submodule_git_url:gsub("^git://github.com/", "")
                ok = ok > 0
                if not ok then
                    fail(element.submodule_git_url, downloads[url].savePath)
                else
                    local _, _, nUser, nRepo = gitURL:find("([^/]*)/(.*).git$")
                    if not (nUser or nRepo) then
                        fail(element.submodule_git_url, downloads[url].savePath)
                    else
                        list[#list + 1] = {nUser, nRepo, nRepodownloads[url].savePath .. "/" .. element.name}
                    end
                end
            end
        end
        h.close()
    end
    
    download(getBaseURL(user, repo, gitPath, branch), savePath, true)
    while true do
        local e, url, h = os.pullEvent()
        if downloads[url] then
            if e == "http_success" then
                if downloads[url].isAPICall then
                    filter(url, h)
                else
                    save(url, h)
                end
            elseif e == "http_failure" then
                fail(url)
            end
            if #downloads == 0 then
                break
            end
        end
    end
end

while #list > 0 do
    print("Downloading " .. list[1][1] .. "/" .. list[1][2])
    gitGet(table.unpack(list[1]))
    table.remove(list, 1)
    print("Downloaded")
end
print("Downloads finished")
