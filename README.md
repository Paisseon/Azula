# Azula App

## Prerequisites
- macOS 11 or iOS 14 device
- **Decrypted** IPA file
- arm64 dylib(s) to inject
- If you are not using TrollStore, make sure your signer allows for Documents entitlements

## Features
- Lightning fast injection (~0,03 seconds)
- Inject multiple dylibs at once
- Replace Substrate with ElleKit
- Code signature slicing (not recommended unless you use TS)
- Helpful log console

## Usage
1. Install Azula on your device and open
2. Import the decrypted IPA and dylibs
3. Toggle the options you want
4. Tap “Patch” and watch it go

If the patch succeeds, Macs will have a popup asking where to save the patched IPA and iOS devices will save it to the Files.app under Azula folder.

## Known Issues
- Codesign slicing is untested with signing apps like Sideloadly, but it breaks ldid.

## Contributing
Contributions are always welcome! Just make a pull request =)

Please note that the [AzulaKit](%20https://github.com/Paisseon/AzulaKit) repo is where the important code is stored, so issues not directly related to the app frontend should be put there.

## Credits
- [Evelyneee](https://github.com/evelyneee/ellekit)
