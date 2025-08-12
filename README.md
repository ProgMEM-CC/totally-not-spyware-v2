# TotallyNotSpyware v2
re-jailbreak utility for devices initially jailbroken with Chimera on iOS 12.<br>
You can re-jailbreak using a webkit exploit without code-signing.


## Supported Devices
A7-A10 devices running iOS versions 12.0 through 12.5.x that have been jailbroken at least once previously with Chimera.

## Credits
- wh1te4ever (main developer)
- alfiecg24 (stable kernel exploit)
- felix-pb (kernel exploit)
- Samuel Groß (CVE-2020-9802, Webkit Exploit)
- CoolStar and all chimera jailbreak developers
- JakeBlair420 and all TotallyNotSpyware developers (jop chaining, code-execution idea)
- qwertyoruiop (Mach-O loader with +jitMemCpy)

## How to build & run
```
$ cd stages
$ python3 build.py
```
For Development
```
$ python3 server.py
```
For Release 
```
$ python3 release.py
# (And hosting files in release folders...)
```