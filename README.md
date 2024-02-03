# MiABSFD Time and Weather Mod

## Current Features

- **Day/Night cycle**. Time moves in the surface and in the Abyss. Time dilation is accounted for as well (time moves faster depending on how deep you are and where you're travelling to). The time dilation is felt when ascending.

## Todo Features

- [ ] **Weather**
- [ ] More time-based events, like surface people being asleep / present or not

### Maybe Features

- [ ] Add features in-game that take into account time, like sleeping to pass time in the Abyss.

> [!WARNING]
> This mod is experimental and might cause your game to crash during gameplay. Please stock up on Mail Balloons and save regularly.

## Installation

Get and install this mod via Nexus Mods and Vortex (guide also in the link): LINK TO NEXUS PAGE

## Manual / Advanced Installation

1. Get and install UE4SS by following the instructions on this page here: <https://seekerted.github.io/MiABSFD-UE4SS-Guide/>
1. Grab the latest release of this mod.
1. Extract and paste the files into the _executable folder_.

### Uninstalling

To disable just the mod but keep UE4SS, delete `Mods\<this mod's folder>\enabled.txt`. To re-enable the mod, just re-create it (it's an empty text file).

To uninstall everything, simply revert the _executable folder_ back to the state before you pasted everything in.

## Credits

Special thanks to:
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)
- UE4SS Discord
- Made in Abyss: Modding Community Discord
- Psitégrad's Map Information document
- Cats' MIA tweaks 0.0.4 mod (the original day/night cycle mod)

## Changelog

```text
0.3.7
- Initial implementation of time ticking in game. Time speed depends on depth and ascent/descent.
```