---
layout: blog
title: "UI Overhaul and Boost System Refactor"
date: 2025-05-15
---

# May 15, 2025: UI Overhaul and Boost System Refactor

Today was a transformative day for Blob Race, marked by a sweeping overhaul of the user interface and a major refactor of the boost system. The game now feels more polished, intuitive, and dynamic than ever before.

The day began with a series of improvements to the UI. The start menu now features a clear version display and more inviting prompts, making it easier for new players to jump in. The blob selection screen was enhanced with better labels and visual feedback, while the “locked in” state now delivers a more exciting sense of anticipation before the race begins. The countdown sequence and racing state both received visual upgrades, making the action more engaging and easier to follow. Finally, the results screen was revamped to provide clear, celebratory feedback for winners and encouragement for those who didn’t win.

On the technical side, the boost system underwent a significant refactor. The logic for player and opponent boosts was extracted into dedicated helper functions, making the codebase cleaner and easier to maintain. The opponent’s boost behavior is now more dynamic, with randomized boost lengths and a smarter cooldown system, adding unpredictability and excitement to every race. Helper functions were also introduced for updating blob speeds and checking win conditions, further streamlining the game loop.

Throughout the day, small but important fixes were made, including correcting version typos and ensuring local variables were properly scoped. The culmination of these changes was a successful merge of the refactor and UI improvement branches, bringing all enhancements together into the main codebase.

Blob Race is now more fun, readable, and maintainable than ever. With these foundations in place, the game is ready for even more features and polish in the days ahead!
