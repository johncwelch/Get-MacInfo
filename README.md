# Get-MacInfo
This eventually will be a powershell module for PS on macOS that will, as much as possible, replicate "Get-ComputerInfo". That's a really handy thing to have, and it not being available on the Mac is annoying as heck. So this is my attempt. Currently, it's a script that grabs info out of a few things and shoves them all into a hashtable. Running it gets you everything, but the idea will be that like Get-Computerinfo, once this is a module, you can import it, and then within powershell, get one or more hardware properties for your mac.

This initial version is pulling data from uname, sw_ver, system_profiler, and Powershell's Get-Culture. 
