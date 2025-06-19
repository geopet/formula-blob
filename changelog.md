# Changelog

---

## [1.0.0] - 2025-06-18

### 🚀 Added

- **Blob Names:**
  - Introduced unique, randomly generated names for blobs, such as "Blobzilla" and "Max Verblobben."
  - Ensured names are unique for each race.

- **UI Enhancements:**
  - Added a `print_centered` helper function to streamline text alignment across the game.
  - Centered text for welcome messages, instructions, and race results.
  - Improved blob selection screen with dynamic name layouts and clearer labels.

- **Race Mechanics:**
  - Enhanced boost mechanics with balanced bonus calculations based on speed gaps.
  - Introduced randomized false starts during the countdown phase for added excitement.
  - Added a dynamic scoring system with moneyline-style risk/reward mechanics.

- **Audio and Visuals:**
  - Added dynamic music that changes based on game state.
  - Introduced new sound effects for boosts, false starts, and race results.
  - Implemented a blob parade animation on the start screen.

- **Post-Race Celebrations:**
  - Added fireworks and celebratory sound effects for race victories.
  - Enhanced result screen with animations for winning and losing blobs.

### 🎨 Visual Enhancements
- **Racetrack Visuals:**
  - Introduced a detailed racetrack background with added grit and texture for a more immersive racing experience.
  - Implemented a helper function `draw_track()` to render the track dynamically during races.
- **Animated Blob Sprites:**
  - Added unique animations for blobs, including running, bobbing, and boosting states.
  - Enhanced blob animations with dynamic sprite flipping and frame transitions for a lively race atmosphere.
- **Start Screen Parade:**
  - Introduced an animated blob parade on the start screen, featuring unique sprites and seamless looping.

### 🎵 Audio Enhancements
- **Sound Effects:**
  - Added distinct sound effects for boosts, false starts, and race results.
  - Introduced celebratory sound effects for race victories, enhancing the post-race experience.
- **Dynamic Music:**
  - Updated the game soundtrack to include dynamic music that changes based on the game state, adding excitement and immersion.

### 🏁 Gameplay Mechanics
- **Boost System Overhaul:**
  - Refactored boost logic for both players and opponents, introducing randomized boost lengths and smarter cooldown systems.
  - Added visual and audio feedback for boost activation and overheating.
- **False Starts:**
  - Implemented randomized false starts during the countdown phase, adding unpredictability and excitement.
- **Race Odds and Moneyline:**
  - Introduced a moneyline-style scoring system, displaying risk/reward values dynamically in the UI.

### 🎉 Post-Race Celebrations
- **Fireworks System:**
  - Added a `spawn_fireworks` function to celebrate race victories with vibrant, animated fireworks.
- **Enhanced Result Screen:**
  - Transformed the result screen into a celebratory display, featuring animations for the winning blob and a crown for player victories.

### 🛠️ Changed / Enhanced

- Refactored boost logic for clarity and maintainability.
- Improved logging system with a `quick_log` table for targeted debug output.
- Updated blob selection UI to display risk/reward values dynamically.
- Polished countdown visuals with starting lights and synchronized sound effects.

### 🔧 Refactored

- Consolidated per-blob state into a single table for better organization.
- Streamlined boost and scoring logic with helper functions.
- Centralized initialization logic for cleaner code structure.

---

## [0.1.0] - 2025-05-01

### 🚀 Added

- **Race Mechanics:**
  - Introduced full race logic, enabling two-blob racing with dynamic position/speed updates and winner detection.
  - Added end-of-race message system to give feedback on victory or defeat.
  - Implemented race display visuals, showing blobs in action with speed/position data.
  
- **Countdown System:**
  - Added a new "countdown" state to transition from blob selection to racing with visual countdown ("3", "2", "1", "go!").
  - Included a helper function (`countdown_msg()`) for rendering countdown messages.

- **Blob Selection:**
  - Introduced blob selection mechanic with left/right choice and lock-in confirmation.
  - Added a "locked_in" state to finalize selection before the race begins.

- **Visual Enhancements:**
  - Animated blob selection with dynamic pulsing effects.
  - Added bobbing/moving arrows and highlights to indicate selection.
  - Programmatically generated initial blob sprites using `circfill`.

- **Audio Feedback:**
  - Added sound effects for blob selection and locked-in confirmation.
  
- **Core Architecture:**
  - Set up a basic state machine to manage game states cleanly.

### 🛠️ Changed / Enhanced

- Fine-tuned blob speed generation to avoid races with extremely low speeds, enhancing gameplay excitement.
- Improved result screen to display race winner and provide tailored feedback.
- Updated `blob_race.p8` header to version "blob race 1.0."

### 🔧 Refactored

- Added logging helper function to centralize debug output.
- Put race telemetry behind a logging toggle for better debug control.
- Refactored countdown messaging for improved readability and maintainability.

### 🐛 Fixed

- Ensured blob speed randomness provides a more dynamic and entertaining race experience.

---

## Initial Project Setup

- Added initial project files and structure to kick off **Blob Race** development.