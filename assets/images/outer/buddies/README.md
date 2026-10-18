# OUTER!ENGINE assistant buddy assets

Place one Sparrow atlas per assistant in this folder:

- `minusbright.png` + `minusbright.xml`
- `outerqt.png` + `outerqt.xml`
- `outersky.png` + `outersky.xml`
- `outerskyblue.png` + `outerskyblue.xml`
- `outernikku.png` + `outernikku.xml`
- `outercarol.png` + `outercarol.xml`

Each atlas should have animation prefixes named `idle`, `walk`, and optionally `drag`.
Capitalized variants (`Idle`, `Walk`, `Drag`) are also attempted. The buddy controller
uses a purple placeholder if an atlas cannot be loaded, so missing optional artwork does
not prevent the editor from opening.

## Current scope

`backend.outer.desktop.DesktopBuddy` is a draggable, animated Flixel sprite that wanders
horizontally within the current game window. It is **not yet a separate native Windows
desktop window**. A true desktop pet needs a native transparent/topmost window host and a
separate rendering/input loop; this class is the reusable animation controller for that
host, not a claim that native desktop integration is already implemented.

## Example

Inside a state/substate after creating the buddy:

```haxe
var buddy = new backend.outer.desktop.DesktopBuddy("minusbright", 40, 400, 1);
add(buddy);
```

The example assumes the matching atlas exists under `assets/images/outer/buddies/`.
