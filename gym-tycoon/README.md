# 🏋️ Gym Tycoon (Roblox / Luau)

Build your own gym, buy equipment, hire staff, earn money from NPC customers who come in to work out, then rebirth to earn even more.

## Features

- **Your own gym plot.** Each player gets one of 6 plots automatically when they join.
- **Buy pads.** Step on a pad to buy what's shown on it. Green means you can afford it, red means you can't yet. New pads appear as you buy things.
- **11 kinds of equipment:** treadmills, dumbbell rack, bench press, squat rack, rowing machine, punching bag, cable machine, yoga mats, smoothie bar, sauna and a boxing ring. Customers actually work out on them, with animations.
- **Decor:** walls, rubber floor, plants, mirrors, speakers, and a giant neon sign with your name on it.
- **Upgrades:** flyers, billboard and TV ads, three membership tiers, a bigger locker room, and a card reader that collects cash for you.
- **🧑‍💼 Staff you can hire.** These are NPCs that walk around your gym doing their job:
  - **Receptionist** stands behind the front desk and doubles check-in fees.
  - **Personal Trainers ×3** walk to whoever is working out and cheer them on ("One more rep!"). They give +20%, +25% and +35% income.
  - **Janitor** walks around mopping and gives +6 gym rating.
  - **Gym DJ** gets a DJ booth and dances behind it. +40% customer arrivals.
  - **Gym Manager** walks the floor with a clipboard. Customers use one more machine per visit.
- **🔁 Rebirths.** Once you own the Boxing Ring and have enough cash, open the Rebirth menu. Your gym and cash reset, but you get **+50% income forever** for each rebirth. Strength and gamepasses stay. Each rebirth costs 2× the last one.
- **🛒 Gamepass shop** with 2x Cash, Auto Collect, VIP Gym (+50% customers, +5 capacity) and Super Strength (2x Strength).
- **Work out yourself.** Walk up to any machine and hold **E** to gain 💪 Strength. Each point adds +0.2% income, up to +200%.
- **Saving.** Cash, Strength, Rebirths and everything you've built are saved.
- **HUD** showing cash, rating, customers, strength, rebirths and your income multiplier, plus the Shop and Rebirth buttons and popup messages.

Nothing needs to be imported. Every model is built from Parts in code.

---

## Step 1: Put the scripts in Roblox Studio

1. Open Roblox Studio and create a new **Baseplate** place.
2. Create each of these and paste in the file's contents. **The names must match exactly**, including capital letters.

| Create this | Where | Paste from |
|---|---|---|
| **ModuleScript** named `GymConfig` | `ReplicatedStorage` | `src/shared/GymConfig.luau` |
| **Script** named `GymServer` | `ServerScriptService` | `src/server/init.server.luau` |
| **ModuleScript** named `Builder` | *inside* `GymServer` | `src/server/Builder.luau` |
| **ModuleScript** named `Customer` | *inside* `GymServer` | `src/server/Customer.luau` |
| **ModuleScript** named `DataService` | *inside* `GymServer` | `src/server/DataService.luau` |
| **ModuleScript** named `GamePasses` | *inside* `GymServer` | `src/server/GamePasses.luau` |
| **ModuleScript** named `Plot` | *inside* `GymServer` | `src/server/Plot.luau` |
| **ModuleScript** named `Remotes` | *inside* `GymServer` | `src/server/Remotes.luau` |
| **ModuleScript** named `Rig` | *inside* `GymServer` | `src/server/Rig.luau` |
| **ModuleScript** named `Staff` | *inside* `GymServer` | `src/server/Staff.luau` |
| **LocalScript** named `GymHUD` | `StarterPlayer > StarterPlayerScripts` | `src/client/GymHUD.client.luau` |

How to create one: hover over the parent in the **Explorer**, click the **+**, pick the type (Script / LocalScript / ModuleScript), press F2 to rename it, then double-click it, delete the default code and paste.

Your Explorer should look exactly like this:

```
ReplicatedStorage
  └─ GymConfig            (ModuleScript)
ServerScriptService
  └─ GymServer            (Script)
       ├─ Builder         (ModuleScript)
       ├─ Customer        (ModuleScript)
       ├─ DataService     (ModuleScript)
       ├─ GamePasses      (ModuleScript)
       ├─ Plot            (ModuleScript)
       ├─ Remotes         (ModuleScript)
       ├─ Rig             (ModuleScript)
       └─ Staff           (ModuleScript)
StarterPlayer
  └─ StarterPlayerScripts
       └─ GymHUD          (LocalScript)
```

(Using Rojo instead? Run `rojo serve` in this folder and connect the Rojo plugin. `default.project.json` puts everything in the right place.)

## Step 2: Test it

1. Click **Play** (or press F5). You'll spawn in front of your gym.
2. Walk onto the green **Treadmill** pad to buy it. Customers start walking in within a few seconds.
3. Step on the gold **REGISTER** pad to collect the money they pay.
4. Keep buying pads. Use the **🛒 Shop** and **🔁 Rebirth** buttons on the left of the screen.
5. If something breaks, open **View → Output** and look for red error text.

**Tip:** to test gamepasses without paying, set `Config.GiveAllPassesInStudio = true` in `GymConfig`. Set it back to `false` before you publish.

## Step 3: Publish it

1. **File → Publish to Roblox**, then give it a name.
2. **Home → Game Settings → Security**, then turn on **Enable Studio Access to API Services**. Saving won't work in Studio without this.
3. On **create.roblox.com → Creations → your game**, set it to **Public** so other people can play.

## Step 4: Set up the gamepasses

1. Go to **create.roblox.com → Creations → your game → Monetization → Passes → Create a Pass**.
2. Make 4 passes: *2x Cash*, *Auto Collect*, *VIP Gym*, *Super Strength*. Upload an icon for each.
3. Open each pass, go to **Sales**, turn on **Item for Sale** and set a price.
4. Copy each pass's **ID** (the number in its URL) into `Config.GamePasses` in `GymConfig`:

```lua
DoubleCash = { Order = 1, Id = 123456789, ... },
```

Any pass with `Id = 0` shows as "Coming soon" in the shop.

---

## Changing the game

Everything you'd want to change is in **`GymConfig`**:
- `Config.Items` holds every buyable item and staff member: price, position, requirements, rating, customer pay and bonuses.
- `Config.Customer` controls how often customers spawn, the entry fee, walk speed and wait time.
- `Config.Rebirth` sets the required item, cost, cost growth and income bonus per rebirth.
- `Config.GamePasses` holds the pass IDs, names and descriptions.

To add a new machine, write a builder in `Builder.luau` (copy `Treadmill`), then add an item with `Model = "YourBuilderName"`.
To add a new staff job, add a role in `Staff.luau` (copy `Janitor`), then add an item with `Kind = "Staff", Role = "YourRole"`.
