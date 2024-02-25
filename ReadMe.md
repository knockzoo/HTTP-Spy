## HTTP Spy
This HTTP spy is designed for **basic** penetration testing and network debugging. It is **not** designed for advanced penetration testing.
It does not feature bypassing techniques or other methods of being undetected. It simply works.
### Usage
```lua
local repo = string.match("https://github.com/%s/%s/main.lua", "realstufflol", ")
loadstring(game:HttpGet(""))()
```
