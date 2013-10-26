rem ¹Ø±Õ explorer.exe
taskkill /f /im explorer.exe
attrib -h -i %userprofile%\AppData\Local\IconCache.db
del %userprofile%\AppData\Local\IconCache.db /a
rem ´ò¿ª explorer.exe
start explorer