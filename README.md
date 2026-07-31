# 🪰 Vanessa-on-the-Loose

<p align="center">
  <img src="assets/background/splash_screen .png" alt="Vanessa-on-the-Loose Splash Screen" width="600">
</p>

> A Filipino market-management survival game built with [Godot 4.6](https://godotengine.org/).

**Vanessa-on-the-Loose** (internally codenamed *bangaw*) is a 2D time-management and resource-management game where you take on the role of **Vanessa**, a stall owner navigating the chaos of Filipino market life. Swat flies, serve customers, manage your finances, and survive escalating market conditions — or face bankruptcy and a ruined reputation.

Learn more about the project at: [https://vanesa-on-the-loose-about.netlify.app/](https://vanesa-on-the-loose-about.netlify.app/)

---

## 🎮 Gameplay Overview

Each in-game **day** lasts **60 seconds**. You must:

- **Restock food** at the start of each day at a dynamic market price.
- **Protect your stock** from hungry flies that land and eat your products.
- **Serve customers** whose hands reach for your food before it spoils.
- **Finish the day in profit** while balancing reputation, customer satisfaction, and your wallet.

Between days, you'll review a financial report and a **forecast** showing your starting capital for the next day. If you cannot afford restocking, bankruptcy strikes accumulate — **three strikes and it's game over**.

### Core HUD Stats

| Stat | Description |
|------|-------------|
| 💰 **Money** | Your current wallet balance. |
| 📊 **Reputation** | Market reputation (0–150). Reaches 0 → game over. |
| 😤 **Satisfaction** | Customer satisfaction (0–150). Reaches 0 → game over. |
| 🪰 **Flies Left** | Active flies remaining on screen. |
| ✅ **Swatted** | Total flies killed this run. |

---

## 🕹️ Controls

| Input | Action |
|-------|--------|
| **Left Mouse Click** | Swat / attack |
| **Pause Button** | Pause / Resume |
| **Esc / Menu Button** | Return to main menu |

> **Note:** The mouse cursor is hidden during active gameplay. The swatter follows your cursor.

---

## 🏪 Market System

Different **market events** rotate every 5 days. Each event changes:

- The **food category** favored for restocking.
- **Fly behavior mix** (e.g., Night Market spawns *Invisible* and *Blink* flies).
- **Price modifiers** for stock and sell values.
- **Spoilage rates** and **customer spawn intensity**.

### Available Markets

| Market | Favored Food | Notable Traits |
|--------|-------------|----------------|
| 🥬 **Filipino Vegetable Market** | Vegetable | Balanced difficulty |
| 🥩 **Filipino Meat Market** | Meat | *Tank* and *Mother* flies |
| 🍎 **Filipino Fruit Market** | Fruit | *Swarm* and *Mother* flies |
| 🌙 **Night Market** | Mixed | *Invisible* & *Blink* flies |
| 🌧️ **Rainy Market** | Mixed | *Poison* & *Swarm* flies; fastest spoilage |

---

## 🪰 Fly Types

Flies have unique behaviors, health, speed, and unlock timings.

| Fly Type | Traits |
|----------|--------|
| **Normal** | Standard behavior. |
| **Swarm** | Small, fast, lower health. |
| **Tank** | Slow, high health, high damage. |
| **Mother** | Lays eggs on food; hatches into smaller flies. |
| **Queen** | Boss-exclusive variant of Mother. |
| **Invisible** | Blends into background (Night Market). |
| **Blink** | Teleports short distances (Night Market). |
| **Poison** | Leaves poison trails (Rainy Market). |
| **Speed** | Very fast movement. |
| **Armored** | High knockback resistance. |
| **Mega** | Large, very high health. |

---

## 👥 Customers

Customers enter from the top of the screen and attempt to grab a food item. They have a **patience meter** — if it drains to zero, they leave disgusted and your **satisfaction** drops.

**Warning:** Never swat a customer's hand. Doing so severely damages satisfaction and may end your run.

---

## ⚔️ Swatter & Upgrades

You can spend money during a day to upgrade your swatter:

| Upgrade | Effect |
|---------|--------|
| **Damage** | +1 damage per level; increases critical hit chance. |
| **Speed** | Reduces attack cooldown and energy cost per swat. |
| **Energy** | Raises maximum energy and speeds up passive regeneration. |

---

## ✨ Skills

One-shot abilities purchased once per day. They have a timed duration and a money cost.

| Skill | Cost | Duration | Effect |
|-------|------|----------|--------|
| **Mega Swatter** | ₱100 | 10s | Doubles swatter area and +50% damage. |
| **Instant Energy** | ₱200 | 5s | Removes all energy costs from swatter attacks. |
| **Fresh Goods** | ₱300 | 5s | Protects all food from fly damage and resets spoilage. |
| **Big Fan** | ₱500 | 10s | Pushes all non-boss flies to one side of the screen. |

---

## 👹 Boss Rounds

Every **10th day** is a **Boss Round**.

- All normal customers and flies are cleared.
- A **Boss Fly** enters the arena with high health.
- **Knight Guard** flies spawn to protect the boss and intercept your attacks.
- Defeat the Boss Fly to survive the day and earn bonus rewards.

Boss round difficulty scales with day count — guard count increases every 10 days.

---

## 💸 Financial System

### Earning Money
- **Gross Sales**: Food sold to customers at its current freshness-adjusted value.
- **Fly Bounty**: Bonus payout per fly killed (scales with day count).
- **Leftover Stock**: Any remaining food is sold at end-of-day value.

### Spending Money
- **Restock Costs**: Dynamic prices based on market event, day inflation, and daily price roll.
- **Upgrades**: Permanent swatter improvements.
- **Skills**: Consumable one-shot abilities.

### Bankruptcy System
If your **starting capital** for a day goes negative, you receive a **bankruptcy strike**.
- **3 strikes** = permanent game over.
- Bankruptcy strikes are shown on the pre-day forecast screen.

---

## 🍤 Food System

- Food spawns inside a **container area** (varies per market).
- Each food item has a **freshness bar** and a dynamic **sell value** that decreases as it spoils.
- **Spoilage** accelerates based on market event and day count.
- **Eggs** laid by Mother flies on food are a contamination hazard — selling food with eggs penalizes reputation and satisfaction.

---

## 🛠️ Project Structure

```
bangaw/
├── assets/                  # Game assets (sprites, fonts, audio, backgrounds)
│   ├── background/          # Market backgrounds, game over, splash screen
│   ├── Flies/               # Fly sprites by type
│   ├── customer/            # Customer hand sprites
│   ├── font/                # PixelifySans, Jersey10
│   ├── icon/                # Upgrade and skill icons
│   ├── ui_container/        # UI panels (result board, boss warning, etc.)
│   ├── weapon/              # Swatter sprites
│   └── Sound Effects/       # SFX and ambient audio
├── Backend/                 # Game logic
│   ├── Game.gd              # Main game controller
│   ├── Game/
│   │   ├── GameConfig.gd    # Constants and asset references
│   │   ├── GameFlow.gd      # Day start/end, run lifecycle
│   │   ├── GameSystems.gd   # Core system updates (flies, customers, skills)
│   │   └── GameUI.gd        # HUD and menu management
│   ├── MarketProgression.gd # Day-based market events, pricing, difficulty
│   ├── Swatter.gd           # Swatter weapon logic and upgrades
│   ├── Buy_skills.gd        # Skill definitions and types
│   ├── AudioManager.gd      # Global audio management
│   ├── RewardManager.gd     # Score and progression rewards
│   ├── SceneFlow.gd         # Scene transitions
│   ├── Object Initialization/ # Data definitions
│   │   ├── Fly_Attributes.gd
│   │   ├── Foods_Attributes.gd
│   │   ├── CustomerHand_Attributes.gd
│   │   ├── BossFly_Attributes.gd
│   │   └── FlyEgg.gd
│   └── Object Behavior/     # Runtime scripts
│       ├── Fly.gd
│       ├── BossFly.gd
│       ├── BossKnightGuard.gd
│       ├── Food.gd
│       ├── CustomerHand.gd
│       └── container.gd
├── Objects/                 # Godot scene files (.tscn)
├── project.godot            # Godot project configuration
└── export_presets.cfg       # Export settings
```

---

## 🚀 Getting Started

### Prerequisites

- [Godot 4.6](https://godotengine.org/download) (GL Compatibility renderer)
- Windows / macOS / Linux

### Running the Project

1. Clone or download this repository.
2. Open `project.godot` in Godot 4.6.
3. Press **F5** or click **Play** to run the project.

The main scene is configured in `project.godot`:
```
config/features=PackedStringArray("4.6", "GL Compatibility")
```

### Exporting

Export presets are included in `export_presets.cfg`. Use Godot's export dialog to build for your target platform.

---

## 🧠 Design Notes

- **Engine**: Godot 4.6, GL Compatibility renderer
- **Resolution**: 1152 × 648 (16:9)
- **Fonts**: PixelifySans (UI), Jersey10 (countdowns/titles)
- **Currency**: Philippine Peso (₱)
- **Language**: GDScript (strict typing enabled throughout)

---

## 📖 Learn More

For the full project background, design goals, and developer notes, visit:

👉 **[https://vanesa-on-the-loose-about.netlify.app/](https://vanesa-on-the-loose-about.netlify.app/)**

---

## 📝 License

*(Add your license here.)*

---

<p align="center">
  Made with Godot • Vanes-on-the-Loose • bangaw
</p>
