# MiA Time and Weather Mod

## Current Features

- **Day/Night cycle**. Time moves in the surface and in the Abyss. Time dilation is accounted for as well (time moves faster depending
on how deep you are and where you're travelling to).

## Todo Features

- [ ] **Weather**
- [ ] More time-based events, like surface people being asleep / present or not
- [ ] Visual indicator of time

### Maybe Features

- [ ] Add features in-game that take into account time, like sleeping to pass time in the Abyss.

## Installation

If you've already installed UE4SS previously (maybe from another one of my mods?) you can skip to the mod part.

### Install UE4SS

1. Download [UE4SS Experimental Release v2.5.2-570](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental) (`UE4SS_v2.5.2-570-g37e727b.zip`).
1. Make a backup of the game's _executable folder_ (`\steamapps\common\MadeInAbyss-BSFD\MadeInAbyss-BSFD\Binaries\Win64`). This is so that you can revert the game back to a clean slate in case something happens.
1. Extract `UE4SS_v2.5.2-570-g37e727b.zip` into the _executable folder_.

### Install this mod

1. Grab the latest release of this repository, or just download/clone.
1. In your copy of the repository, paste all the files inside the top folder into the _executable folder_.

## Usage

After doing the above, the mod injector (UE4SS) and this mod itself should be installed and you can just run the game.

> [!CAUTION]
> This mod is experimental and might cause your game to crash during gameplay. Please stock up on Mail Balloons and save regularly.

This mod only affects gameplay, so your saves should be unaffected regardless if you have the mod or not, but I'm not 100% sure. **Please create backups always.**

### Uninstalling

To disable just the mod but keep UE4SS, delete `Mods\seekerted-TimeAndWeather\enabled.txt`. To re-enable the mod, just re-create it (it's an empty text file).

To uninstall everything, simply revert the _executable folder_ back to the state before you pasted everything in (or just deleting `xinput1_3.dll` should suffice).

## Credits

Special thanks to:
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)
- UE4SS Discord
- Made in Abyss: Modding Community Discord
- Psitégrad's Map Information document
- Cats' MIA tweaks 0.0.4 mod (the original day/night cycle mod)

## Changelog

```
0.3.7
- Initial implementation of time ticking in game. Time speed depends on depth and ascent/descent.
```