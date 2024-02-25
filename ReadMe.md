## HTTP Spy
This HTTP spy is designed for **basic** penetration testing and network debugging. It is **not** designed for advanced penetration testing.
It does not feature bypassing techniques or other methods of being undetected. It simply works.
### Warning
I do not claim responsibility for any damages caused by using this script. I strongly suggest not using it without proper authorization and permission.
This will likely be detected by any anti HTTP spies, such as those found in whitelists.

**Use at your own risk.**
### Usage
```lua
local repo = string.match("https://github.com/%s/%s/main.lua", "realstufflol", "HTTP-Spy")
loadstring(game:HttpGet(""))()
```
