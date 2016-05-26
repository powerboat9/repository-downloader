local user, repo, savePath, gitPath, branch = ...

local function getBaseURL(path)
    path = fs.combine(gitPath, path)
    return baseURL = ("https://api.github.com/repos/%s/%s/contents/%s"):format(user, repo, path) .. (branch and ("?ref=" .. branch)) or ""
end

local function getTime()
    return os.time() + os.day() * 24000
end

local downloads = {}
local function download(path, type)
    local sPath = fs.combine(savePath, path)
    local downURL = getBaseURL(path)
    downloads[downURL] = {type = type, path = sPath}
    http.request(downURL)
end

local function save(url, h)
    if downloads[url] and (downloads[url].type == "file") then
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
        if term.isColor() then new = colors.blue else new = colors.grey end
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
        data = data:gsub("\"([^\"]*)\"%s*:%s*", "%1 = "):gsub("[", "{"):gsub("]", "}")
        data = textutils.unserialize(data)
        if data[1] then
            for _, element in ipairs(data) do
                if element.type == "file" then
                    download(element.path, element.type
    h.close()
    
