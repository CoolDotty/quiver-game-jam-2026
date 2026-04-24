This is a Godot engine game

Always use godot 4 syntax

Always follow `skills/godot-best-practices.md`

You have `godot-mcp` cli at your disposal.

Use `godot-mcp --list-tools` to see avaliable tools

When making nodes and scenes, make them as bespoke scenes encapsulating the high level concept in an object oriented matter

Resources can be inline as a scene resource, unless it makes sense to seperate it out for re-use in more scenes

ex: user says make a goblin -> make a new goblin scene -> make essential child nodes inside that scene -> make a goblin.gd and attach it to root -> code inside the script.

Always follow "Signal up, call down". Nodes talking to siblings or parents need to do so by broadcasting signals.

When in doubt, add a signal to a global script and let your scene emit that and any listeners can listen to that

eg: when goblin dies, increase player coins -> Global.gd signal goblin_died -> goblin.gd on_die(): Global.goblin_died.emit() -> player.gd on_ready(): Global.goblin_died.connect(add_kill_reward)

For calling down, if a node is concerned about a child, that child node should be a part of that node's scene and the parent can call it with a direct child path

eg: goblin needs to change sprite to red -> goblin.gd @onready var sprite_2d: Sprite2D = $Sprite2D -> sprite_2d.modulate = Color.RED

If you need a placeholder texture, use `assets/placeholders/DevTextures`. It's various grids of different colors

If you need a more specific placeholder, like an apple.png or something, ask the user to add one in `assets/placeholders/[placeholder file]`

`assets/placeholders/icon.svg` is already in there for your convinience
