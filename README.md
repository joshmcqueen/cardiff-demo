# Cardiff Game Demo

A two-room point-and-click learning project for **Godot 4.7.2**, using GDScript and editable 2D scenes. Everything is made from Godot shapes, labels and controls; no external art or plugins are needed.

## Start here

1. Open `project.godot` in Godot.
2. In the FileSystem dock, double-click `game/main.tscn`.
3. Press **⌘B on macOS** (**F5 on Windows/Linux**), or click the Run Project triangle at the top right. Main is already configured as the starting scene.
4. Click the square **Stop** button in the editor to stop. Running again starts a fresh puzzle.

Use **Run Project** for gameplay. **Run Current Scene** runs only the selected scene: a room on its own shows its scenery, but does not include Main's player and interface. Godot documents the [platform-specific Run Project shortcuts](https://docs.godotengine.org/en/latest/getting_started/step_by_step/nodes_and_scenes.html#setting-the-main-scene).

If an older standalone demo window is still open, close it and run again from Godot to load the latest scripts.

## Learn it in three passes

These passes use the same completed project. You do not need to switch versions or uncomment code.

### 1. Movement and boundaries

Run Main and click the courtyard floor. The character walks there, routing around the crate. Click beyond the floor boundary and the character ignores it. Click another valid destination while moving to redirect the character.

Press **F1** to see the actual navigation polygons in green. Gold crosses mark object approach points and room entrances. The player's root position represents their feet; their artwork extends upward from that point.

Open `player/player.tscn`, select the **Player** root and change **Walk Speed** in the Inspector. Use Run Project to see the difference. Change properties while the game is stopped if you want to save them.

Open `rooms/courtyard.tscn` and select **NavigationRegion2D**. Its **Navigation Polygon** resource holds the walkable area. The crate is excluded from that area; a visible shape alone does not block navigation.

### 2. Hotspots and inventory

Click the key. The player first walks to its **Approach** marker, then picks it up. The key disappears from the courtyard and is added to inventory once.

Move the mouse into the top 20 pixels of the game canvas. The inventory slides and fades down. It stays open while you browse and closes when you move away. Click the **Gate key** slot to select it. Its name follows the cursor. Right-click or press **Escape** to cancel selection.

The drawer shows six slots. With more than six collected items, a right arrow appears at the far right. Scrolling one item reveals a left arrow at the far left. Arrows disappear at the ends; the list does not wrap. The normal puzzle has only one item, so it does not show overflow arrows.

Open `ui/interface.tscn` to inspect the UI. **Root → Drawer** contains the arrow buttons, slot container and headings. The script controls its animation. UI clicks are handled before world clicks so browsing cannot make the character walk underneath.

Open the courtyard and expand **Hotspots → Key**. Select Key to see its exported **Display Name**, **Examination**, **Hit Size**, **Pickup Item** and **Hotspot Id** fields. Select its **Approach** child to move where the character stands before collecting it. The yellow rectangle visible in the editor is the clickable area.

### 3. Puzzle and connected rooms

1. Click the gatehouse door without a selected item. The character walks to it and reports that it is locked.
2. Collect the key if necessary. Reveal inventory and select **Gate key**.
3. Move away from the drawer and click the gatehouse door. The character walks to the approach point and unlocks it. The key stays in inventory; selection clears.
4. Click the door again to enter. Hovering over it displays an upward exit arrow. The screen briefly fades while the room changes.
5. Click the bell inside the gatehouse. The character walks over and rings it, completing the demo with a text response.
6. Click the courtyard door to return. Its exit cursor points left. The key remains collected and the door remains unlocked. You can continue moving between rooms.

Right-click any object to examine it without walking. Try using the key on the crate for an unsuccessful-use response. Clicking another destination cancels a queued interaction; changing item selection also cancels a queued action.

Open `rooms/gatehouse.tscn` to inspect the second room. Select an exit hotspot to see **Exit Direction**, **Destination Room**, and **Destination Entrance** in the Inspector. The destination entrance is the exact name of a Marker2D beneath that room's **Entrances** node.

## How the pieces fit

| Piece | Responsibility |
| --- | --- |
| `game/main.tscn` and `main.gd` | Keep one player and interface alive; replace the active room; coordinate clicks, queued actions and puzzle behavior. |
| `player/player.tscn` and `player.gd` | Move along NavigationAgent2D's path and report arrival. Keep feet on the navigation surface. |
| `rooms/room.gd` | Provide room geometry, entrances, hotspot lookup and state-driven visuals. |
| `rooms/hotspot.tscn` and `hotspot.gd` | Reusable click area, approach marker, object description and optional exit/pickup properties. |
| `ui/interface.tscn` and `interface.gd` | Top drawer, scrolling, item selection, hover labels, directional exit cursor and text responses. |
| `game/game_state.gd` | Session inventory, unlocked gate and completed bell. Registered as the GameState Autoload. |
| `game/debug_overlay.gd` | Draw the active room's navigation geometry and markers when F1 is enabled. |

A **scene** is a saved tree of **nodes**. The player, rooms and interface are separate scenes that Main instantiates. Scripts attached to their roots define their behavior. **Signals**, such as the player's `arrived` and GameState's `inventory_changed`, notify the coordinating code when something happens.

## Change a walkable area

1. Stop the game and open the room scene.
2. Select **NavigationRegion2D** and its existing **Navigation Polygon** resource. The resource already contains editable outlines and a baked navigation mesh.
3. Use the polygon tools above the 2D viewport to select and move outline vertices. The outer outline encloses walkable ground; the courtyard's inner outline cuts out the crate.
4. Keep all approach and entrance markers on walkable ground. Leave clearance around scenery for the character's feet. This demo authors that clearance directly, with the navigation resource's **Agent Radius** set to zero.
5. Click **Bake NavigationPolygon** in the navigation toolbar to regenerate the mesh, then save the scene. Editing the outline without baking leaves the previous mesh active.
6. Run Main and use F1 to inspect the result.

Do not move only the visible crate and expect the path to change: move its excluded navigation outline and its hotspot/approach point as well. Main rejects an interaction whose Approach marker lies outside the walkable region and displays a useful response.

## Add a hotspot

1. Open a room, select **Hotspots**, then instantiate `rooms/hotspot.tscn` beneath it.
2. Give the instance a unique node name and **Hotspot Id**. Set **Display Name**, **Examination** and **Hit Size**.
3. Add placeholder art beneath it, or keep the editor's yellow hit rectangle as your placement guide. The rectangle is editor-only; add visible artwork for players to find the object.
4. Right-click the instance and enable **Editable Children** if needed. Position its **Approach** marker on reachable ground.
5. For a collectible, set **Pickup Item** to a unique identifier. `GameState.item_label()` derives its slot label, with a special label for `gate_key`.
6. For an exit, choose **Exit Direction**, assign a destination room scene and enter the destination entrance marker name.

Ordinary objects default to displaying their examination text. Custom actions and item combinations belong in Main's `_complete_pending_interaction()`. The key/door and bell branches are deliberately small examples to learn from.

For an instanced hotspot's children, the supplied rooms already enable Editable Children. The hotspot script also displays editor configuration warnings for missing required properties.

## Add another room

1. Duplicate an existing room scene and give its root a new name and **Room Title**.
2. Update its scenery, visible title labels, navigation outlines and hotspots. Bake and save its navigation polygon.
3. Add named Marker2D children beneath **Entrances**, positioned on walkable ground.
4. Add an exit in an existing room pointing to the new scene and one of its entrance names. Add a return exit in the new room.
5. Run Main and enter through the exit. Main loads the destination scene from the exit's Inspector property; no central room list needs updating.

Duplicating a room also duplicates its hotspot settings, so replace inherited puzzle IDs and pickup IDs instead of accidentally creating a second gate/key/bell.

## Manual checks and current validation

The startup parse error in Main's click-coordinate calculation is fixed with an explicit Vector2 type annotation. The engine integration suite now checks that Main can compile, fails with a nonzero exit status if compilation fails, and has a timeout to prevent a broken test run from hanging.

The integration suite passes **43 checks**, including mouse events delivered through Godot's real GUI/world input pipeline, navigation around the crate, cancellation, inventory selection/scrolling, the key/door/bell puzzle and room-state persistence. The actual game window was also exercised for pickup, drawer reveal, item selection, unlocking, entering the gatehouse, ringing the bell and returning to the courtyard. The drawer renders above room labels so its contents are not overlapped, and that adjustment was checked after restarting the game.

Useful manual checks:

- Click the key, floor and outside bounds; redirect the character while walking. Check routing around both sides of the crate.
- Hover the inventory strip, enter the drawer, leave it and quickly re-enter. Check that it does not flicker or intercept clicks when closed.
- Select/cancel an item and click inventory gaps. Confirm that inventory clicks do not move the character.
- Try the locked door, wrong item use, unlocking and entering. Return repeatedly and confirm state remains consistent.
- Hover both exits and check the cursor arrows. Click during a fade and confirm no extra movement or duplicate transition occurs.
- Resize the game window. Check that it remains proportional, with letterboxing where needed and aligned click targets.
- To exercise overflow manually without adding gameplay objects: pause a running game, switch the Scene dock to **Remote**, select **GameState**, add several unique StringName values to its **Inventory** array, then resume. Add the entries before opening the drawer for the first time, or collect the key afterward so `inventory_changed` refreshes the UI. Restarting clears these temporary items.

The optional engine checks are in `tests/smoke.tscn`; no testing plugin is installed. On this Mac, run them from the project folder with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/smoke.tscn --fixed-fps 60 --log-file /tmp/cardiff-tests.log
```

A passing run prints `Cardiff integration: 43 checks, 0 failures` and exits successfully. The sandboxed engine may also print a macOS system-certificate lookup warning; this demo performs no network requests.

## Deliberate limits

Progress exists only for the current run. There are no imported assets, save files, dialogue trees, sound, menus or external plugins. The bell's “ring” is a text response and color change. The character is a static placeholder silhouette that changes facing direction, with no walk animation yet.

The viewport is 1280×720 with `canvas_items` scaling and preserved aspect ratio. Native window sizing and letterboxing can vary with the editor's embedded game setting and display scale.
