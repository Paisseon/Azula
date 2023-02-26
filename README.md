# Azula
A CLI tool for manipulating load commands in 64-bit Mach-O binaries. Built on [AzulaKit][1]

## Prerequisites
- macOS 11 or iOS 14 device
- Decrypted IPA or Mach-O binary
- Shell access

## Features
- Inject multiple load commands at once
- Remove multiple load commands at once
- Nullify the code signature
- Supports both thin and fat binaries
- Parses load commands only once for performance
- Supports injecting into IPA files
- Pretty coloured output

## Installation
Download the Azula binary from latest release, or compile this project. Then move it to /usr/local/bin.

## Usage
**Base: `Azula <path to an IPA or Mach-O binary>`**

The path must exist on your local file system and be writable. If using an IPA, make sure that the last four characters of the path are “.ipa”.

**Dylibs flag: `-d <comma-separated paths to runtime dylibs>`**

The paths used here are to be how the target will find them during runtime. They aren’t required to exist on your local file system as only the path name is used. For example, `@executable_path/Frameworks/SatellaJailed.dylib` for an iOS app.

If a path already exists in the target, or there is not enough space to add it, an error will be thrown and the injection will fail. 

If a path with the same file name exists, such as `@rpath/something.dylib` when you try to inject `@executable_path/something.dylib`, Azula will warn you

**Remove flag: `-r <comma-separated paths to runtime dylibs>`**

These paths are those which exist in the target. You can check by using `otool -L <binary> | rg "some/path/here.dylib"`

If a path does not exist in the target, a warning about no patches will be thrown and the removal will fail.

**Slice flag: `-s`**

Taking no arguments, this flag just nullifies the code signature so the app doesn’t crash.

## Contributing
Fixing bugs, improving performance, etc. is always appreciated! 

## Credits
- [Ja1dan][2]
- [Jonathan Levin][3] 
- [ParadiseDuo][4] 

[1]:	https://github.com/Paisseon/AzulaKit
[2]:	https://github.com/ja1dan
[3]:	https://annas-archive.org/md5/c2f0370903c27a149b66326d9e584719
[4]:	https://github.com/paradiseduo/inject