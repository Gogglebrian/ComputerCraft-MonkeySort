Simple item sorting script for ComputerCraft. 

Sorts items by name, by tag, by matching current contents, or by matching previously observed contents. In short, just put your items where you want them, and the computer will follow suit.

This script is intended to achieve a visually-appealing, spacially-intuitive, and vanilla-feeling storage front-end for a crafting area.

It pairs well with [artist](https://github.com/SquidDev-CC/artist) as a back-end for high-volume storage.

Usage:
1. Place your chests: input chest, default chest, optionally a dedicated overflow chest, and as many sorted chests as you want (I usually start with 50).
1. Connect your chests to the computer by wired modems, noting each chest's name/number as you enable the modem, eg "minecraft:chest_17".
2. Update the chest names/numbers in monkeySort.lua under the "Storage chests config" heading.
4. Sorting rules can be specified for individual items IDs in item-rules.txt, and for item tags in and tag-rules.txt. The sorting process follows this order of precedence:
    - Individual item rules in item-rules.txt
    - Item tag rules in tag-rules.txt
    - Match by current chest contents (the most recent observations recorded in the observed-contents folder)
    - Match by previous "lapsed" observations in lapsed-observations.txt (eg we ran out of diamonds, but they used to be in chest 13)
    - No match; dump to the default chest
