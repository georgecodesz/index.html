# 🏋️ Gym Tycoon (Roblox / Luau)

Build your own gym, buy equipment, and earn money from NPC customers who come in to work out.

## What's in the game

- **Your own gym plot.** Each player gets one of 6 plots automatically when they join.
- **Buy pads.** Step on a green pad to buy what's shown on it. A red pad means you can't afford it yet. New pads appear as you buy things, so the gym grows step by step.
- **11 kinds of equipment, 33 things to buy in total:** treadmills, dumbbell rack, bench press, squat rack, rowing machine, punching bag, cable machine, yoga mats, smoothie bar, sauna and a boxing ring. There's also decor (walls, rubber floor, plants, mirrors, speakers, a giant neon sign with your name on it) and upgrades (flyers, billboard and TV ads, membership tiers, a bigger locker room, and a card reader that collects cash for you).
- **Customers (NPCs)** walk in from the street and pay an entry fee at the front desk. Each one finds a free machine and works out on it with animations, like running on the treadmill, lifting the barbell, squatting or rowing, then pays you. They use 1–3 machines per visit. If every machine is busy they wait, and if they wait too long they leave angry.
- **Register.** Customer money goes into the gold register pad until you step on it to collect. The Card Reader upgrade makes this automatic.
- **Rating.** Every item adds rating, and higher rating brings customers in faster. More equipment also raises how many customers fit in at once.
- **Work out yourself.** Walk up to any machine and hold **E** to gain 💪 Strength. Each point adds +0.2% to your gym's income, up to +200%.
- **Saving.** Cash, Strength and everything you've built are saved with DataStores.
- **HUD** showing cash, rating, customers, strength, your income multiplier, a register reminder and popup messages.

Nothing needs to be imported. Every model is built from Parts in code, and the customers are standard R15 rigs.

## Setup option A: copy-paste into Roblox Studio (no tools needed)

1. Open Roblox Studio and create a new **Baseplate** place.
2. Create these scripts and paste in each file's contents. **The names must match exactly.**

| Create this | Where | Paste from |
|---|---|---|
| **ModuleScript** named `GymConfig` | `ReplicatedStorage` | `src/shared/GymConfig.luau` |
| **Script** named `GymServer` | `ServerScriptService` | `src/server/init.server.luau` |
| **ModuleScript** named `Builder` | *inside* `GymServer` | `src/server/Builder.luau` |
| **ModuleScript** named `Customer` | *inside* `GymServer` | `src/server/Customer.luau` |
| **ModuleScript** named `DataService` | *inside* `GymServer` | `src/server/DataService.luau` |
| **ModuleScript** named `Plot` | *inside* `GymServer` | `src/server/Plot.luau` |
| **ModuleScript** named `Remotes` | *inside* `GymServer` | `src/server/Remotes.luau` |
| **LocalScript** named `GymHUD` | `StarterPlayer > StarterPlayerScripts` | `src/client/GymHUD.client.luau` |

Your Explorer should look like this:

```
ReplicatedStorage
  └─ GymConfig            (ModuleScript)
ServerScriptService
  └─ GymServer            (Script)
       ├─ Builder         (ModuleScript)
       ├─ Customer        (ModuleScript)
       ├─ DataService     (ModuleScript)
       ├─ Plot            (ModuleScript)
       └─ Remotes         (ModuleScript)
StarterPlayer
  └─ StarterPlayerScripts
       └─ GymHUD          (LocalScript)
```

3. Press **Play**.

## Setup option B: Rojo

```bash
rojo serve
```

Then connect with the Rojo plugin in Studio. `default.project.json` maps everything to the right place.

## Turning on saving

Saving only works in a **published** place:
1. File → Publish to Roblox.
2. Game Settings → Security → turn on **Enable Studio Access to API Services**. You need this for saving to work while testing in Studio.

If saving isn't available, the game still runs. It just prints a warning and won't save.

## Changing the game

Everything you'd want to change is in **`GymConfig`**:
- `Config.Items` holds every buyable item: price, position, what it requires, rating, how much customers pay, and how long a workout lasts. To add another treadmill, copy a line, give it a new `Id` and a new `Position`.
- `Config.Customer` controls how often customers spawn, the entry fee, walk speed, the max wait, and how many machines each one uses.
- `Config.StartingCash`, `Config.StrengthIncomeBonus`, `Config.PlotCount`, and so on.

To add a brand-new kind of machine, write a builder function in `Builder.luau` (copy `Treadmill` as a starting point), then add an item to `Config.Items` with `Model = "YourBuilderName"`.

## Ideas for what to add next
- Rebirths (reset the gym for a permanent income multiplier)
- Hire staff NPCs (a trainer who boosts what customers pay)
- Gamepasses (2x cash, auto-collect)
- Music in the Sound System (add a `Sound` with your own audio ID)
