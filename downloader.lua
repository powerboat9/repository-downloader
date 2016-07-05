local user, repo, savePath, gitPath, branch, next = ...

local function verifyAlphaNumeric(str, errorMSG)
    if not (type(user) == "string") or not (user:gsub("[^%w_]+", "") == user) then
        error(errorMSG, 0)
    end
end

verifyAlphaNumeric(user, "Invalid username")
verifyAlphaNumeric(repo, "Invalid repository")

savePath = type(savePath) == "string" and savePath or "/.APIS/" .. repo
gitPath = type(gitPath) == "string" and gitPath or ""
branch = type(branch) == "string" and branch or nil
next = type(next) == "table" and next or {}

local function getBaseURL(path)
    path = fs.combine(gitPath, path)
    if (path ~= "") and (path:sub(1, 1) ~= "/") then path = "/" .. path end
    return baseURL = ("https://api.github.com/repos/%s/%s/contents%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

local function getPathFromURL(url)
    return url:sub(30):gsub("%?ref=.*$", ""):gsub("^[^/]*/[^/]*/contents/", "")
end

local function getTime()
    return os.time() + os.day() * 24000
end

local downloads = {}
local function download(url, savePath, isAPICall)
    downloads[url] = {isAPICall = isAPICall, savePath = savePath, gitURL = url}
    http.request(url)
end

local function save(url, h)
    if downloads[url] then
        local file = fs.open(downloads[url].path, "w")
        file.write(h.readAll())
        file.close()
    end
    h.close()
end

local function fail(url)
    if downloads[url] then
        local old = term.getBackgroundColor()
        term.write("Downloading \"")
        local new
        if term.isColor() then new = colors.red else new = colors.grey end
        term.setTextColor(new)
        term.write(url)
        term.setBackgroundColor(old)
        term.write("\" failed")
        return true
    end
    return false
end

local function filter(url, h)
    if downloads[url] then
        local data = h.readAll()
        data = data:gsub("\"([^\"]*)\"%s*:%s*", "%1 = "):gsub("[", "{"):gsub("]", "}"):gsub("null", "nil")
        data = textutils.unserialize(data)
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
                
    h.close()
    
