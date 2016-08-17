local list = ...

local function getBaseURL(path)
    --path = fs.combine(gitPath, path)
    if (path ~= "") and (path:sub(1, 1) ~= "/") then path = "/" .. path end
    return baseURL = ("https://api.github.com/repos/%s/%s/contents%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

local function getPathFromURL(url)
    return url:sub(30):gsub("%?ref=.*$", ""):gsub("^[^/]*/[^/]*/contents/", "")
end

local function getTime()
    return os.time() + os.day() * 24000
end

local function unserializeJSON(str)
    return textutils.unserialize(str:gsub("\"([^\"]*)\"%s*:%s*", "%1 = "):gsub("[", "{"):gsub("]", "}"):gsub("null", "nil"))
end

function gitGet(user, repo, savePath, gitPath, branch)
    local function verifyAlphaNumeric(str, errorMSG)
        if not (type(user) == "string") or not (user:gsub("[^%w_]+", "") == user) then
            error(errorMSG, 0)
        end
    end
    
    verifyAlphaNumeric(user, "Invalid username")
    verifyAlphaNumeric(repo, "Invalid repository")
    
    savePath = type(savePath) == "string" and savePath
    savePath = savePath or "/.APIS/" .. repo
    
    gitPath = type(gitPath) == "string" and gitPath or ""
    branch = type(branch) == "string" and branch or nil
    next = type(next) == "table" and next or {}
    
    local downloads = {}
    local function download(url, savePath, isAPICall)
        downloads[url] = {isAPICall = isAPICall, savePath = savePath, gitURL = url}
        http.request(url)
    end
    
    local function save(url, h)
        local file = fs.open(downloads[url].savePath, "w")
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
        local data = unserislizeJSON(h.readAll())
        for _, element in ipairs(data) do
            if element.type == "file" then
                download(element.download_url, downloads[url].savePath .. "/" .. element.name, false)
            elseif element.type == "dir" then
                download(element.url, downloads[url].savePath .. "/" .. element.name, true)
            elseif element.type == "symlink" then
                local f = fs.open(downloads[url].savePath .. "/" . element.name .. ".clnk", "w")
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
                        list[#list + 1] = {nUser, nRepodownloads[url].savePath .. "/" .. element.name, "/"}
                    end
                end
            end
        end
        h.close()
    end
    
    download(getBaseURL(gitPath), savePath, true)
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
    print("Downloading " .. list[1] .. "/" .. list[2])
    gitGet(table.unpack(list[1]))
    table.remove(list, 1)
    print("Downloaded")
end
print("Downloads finished")
