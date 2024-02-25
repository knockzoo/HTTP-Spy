## HTTP Spy
This HTTP spy is designed for **basic** penetration testing and network debugging. It is **not** designed for advanced penetration testing.
It does not feature bypassing techniques or other methods of being undetected. It simply works.
### Warning
I do not claim responsibility for any damages caused by using this script. I strongly suggest not using it without proper authorization and permission.
This will likely be detected by any anti HTTP spies, such as those found in whitelists.

**Use at your own risk.**
### Features
Automatically, this HTTP spy will do the following:
- Replace any instances of your IP address being sent or received by the client with a realistic, randomized version
- Replace any instances of your HWID being sent or received by the client with a realistic, randomized version
- Flag any possibly malicious HTTP requests (This does not block them from being sent)
- Provide a bug-free experience to certain modern executors

And allows you to manually do the following:
- Copy a serialized version of data being sent to your clipboard
- Copy a serialized version of data being received to your clipboard
### Usage
```lua
local repo = string.match("https://raw.githubusercontent.com/%s/%s/%s/main.lua", "realstufflol", "HTTP-Spy", "main")
loadstring(game:HttpGet(repo))()
```
