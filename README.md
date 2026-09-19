# Chat Character Map

Find the right symbol without leaving the game. Chat Character Map puts hearts, accented letters, arrows, maths signs, Greek letters, and raid markers in one searchable window.

Open it with `/charmap`, `/ccmap`, or the book button beside your minimap. Try `/charmap heart` to jump straight to a search.

## Features

- Browse 340 characters and eight raid markers by category.
- Search by name, symbol, Unicode code, or Windows Alt code.
- Save your most-used characters in Favorites.
- Copy a character, insert it into chat, or build a whole message.
- Compare the game's Arial and Friz fonts. Characters missing from the selected font are hidden by default.
- Move the window and minimap button. Their positions are saved.

## How to use it

Click a character, then press **Ctrl+C** to copy it. Right-click it or choose **To chat** to insert it into your chat box.

To build a message, Shift-click characters or use **Add to message**. Choose **Select message** to copy it, or **Insert into chat** to add it to your current chat box. The addon does not send messages: check the channel and press Enter yourself.

Use **Favorite** to keep a character handy. Toggle the minimap button with the **Minimap icon** checkbox or `/charmap minimap`.

## Install

Download the addon ZIP from [Releases](https://github.com/coffeelover1010/chat-character-map/releases). Extract the `ChatCharacterMap` folder into your game's `Interface/AddOns` folder.

The `.toc` and all four `.lua` files must be directly inside `AddOns/ChatCharacterMap`. Restart the game, enable **Chat Character Map**, and type `/charmap`.

## Compatibility

**Version 0.2.1-beta targets the Forever beta (interface 16001).** In-game rendering, minimap dragging, clipboard shortcuts, and chat insertion still need client verification. Support for other WoW clients is not confirmed.

Font coverage was checked against the installed Forever beta fonts on 19 September 2026. The lists include 308 characters in Arial and 132 in Friz. The heart is available in Arial. Other players' fonts and server filtering may affect what they see. The addon uses the game's fonts and does not change your chat settings.

Messages are limited to 255 UTF-8 bytes. Accented letters and symbols can use more than one byte each.

## Character codes

**Unicode:** `U+00E9` identifies `é`; typing the code into chat does not create the character. Copy or insert the character instead.

**Windows Alt codes:** Where listed, these use Windows code page 1252. Hold Alt and type the digits, including the leading zero, on the numeric keypad. Keyboard and game settings can affect the result.

**Raid markers:** `{star}` and `{rt1}` are WoW chat tokens, not Unicode characters. The Raid marks tab shows their icons and codes.

## Credits

Character names and code points come from Python's Unicode database. No external libraries, font files, or artwork are bundled. Raid marker previews use textures already in the game.
