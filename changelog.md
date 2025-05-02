# Changelog

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