# Classic Action Combat

Classic Action Combat is an Addon for World of Warcraft Classic that implements the typical controls found in other MMORPGs that feature action combat.

## Features

* **Toggleable mouselook.** Control the camera by simply moving the mouse - no need to hold the right mouse button anymore!
* **Interact with the world while mouselooking.** Talk to nearby NPCs, loot the last monster you killed and Pick Pocket enemies with a simple press of a button!
* **Target the enemies you are looking at.** No longer will you have to suffer the inconveniences of tab targeting - simply look at an enemy and target it, even if it is far away!
* **Use your main mouse buttons in combat.** Bind spells, macros and items to the left and right mouse buttons. Your mouse buttons can be bound to anything while you're mouselooking!
* **Automatically shows the cursor when you need it.** The addon detects when you open a window, such as your character profile or inventory, and stops mouselooking. Once you close the window, mouselook automatically resumes!

## Requirements

In order for the addon to work correctly, you must have nameplates active. You can enable them by going to Interface Options > Names > Unit Nameplates > Always Show Nameplates.

## Controls

The default controls are the following:

* `Left Alt` - Toggle cursor / mouselook.
* `Left Mouse Button` - Start attacking your current target.
* `Right Mouse Button` - Target the enemy you are looking at. Tip: your character's head acts as a crosshairs.
* `F` - Interact with the world. Talk to nearby NPCs, loot the last monster you killed and Pick Pocket enemies.

## Customization

You can change the keybinds and add or remove windows for automatic cursor display using the following slash commands:

* `/cac reset` - Resets the settings of the addon to its default values.
* `/cac show windows` - Prints the list of windows that cause the cursor to automatically display.
* `/cac add window <name>` - The given window will cause the cursor to automatically display.
* `/cac remove window <name>` - The given window will no longer cause the cursor to automatically display.
* `/cac show keybinds` - Prints the current keybinds of the addon.
* `/cac bind <key> <binding>` - Binds the given key to the given binding. Allowed values for key: BUTTON1, SHIFT-BUTTON1, CTRL-BUTTON1, SHIFT-BUTTON2, CTRL-BUTTON2. Allowed values for binding: [incomplete list](https://wow.gamepedia.com/BindingID).
* `/cac bind INTERACT <key>` - Binds world interaction to the given key. This key will be used to talk to NPCs, loot monsters and Pick Pocket enemies. Allowed values for key: any binding accepted by World of Warcraft Classic (e.g. ALT-CTRL-Q, SHIFT-E, V, BUTTON3).

## Finding names of windows

If you want to add or remove windows that should automatically display the cursor, you need to know their names. In order to do this, simply type `/framestack` in chat and you'll be able to see the name of any window your mouse is hovering. For example, the name of your character window is `CharacterFrame`.

Type `/framestack` once more to disable it.

## Auto Loot

In order to have the best experience with this addon, I suggest you to enable auto loot. You can achieve this by typing `/console autoLootDefault 1`. You can set the delay before the loot window disappears by typing `/console autoLootRate <milliseconds>`.

Type `/console autoLootDefault 0` to disable auto loot. If you play with auto loot disabled, I suggest you to add the loot window to the list of windows that automatically display the cursor.