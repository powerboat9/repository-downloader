local file = shell.dir() .. "/" .. "Makefile"
if not fs.exists(file) or fs.isDir(file) then
    error("Cannot find Make file", 0)
end
