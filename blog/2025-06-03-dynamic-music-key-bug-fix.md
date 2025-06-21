---
layout: blog
title: "Dynamic Music and a Key Bug Fix"
date: 2025-06-03
---

# June 3, 2025: Dynamic Music and a Key Bug Fix

Today’s development session was a blast, bringing fresh energy and polish to Blob Race! With a brand new dynamic music system and a crucial scoring bug fix, the game now feels more alive and fair than ever. These changes not only enhance the atmosphere but also ensure every race is as thrilling and rewarding as it should be.

## Dynamic Music System
A major highlight is the new dynamic music system. Blob Race now changes background music based on the current game state: a welcoming tune plays on the start screen, while a different track sets the mood during blob selection. This is managed by the new `music_player` function, which ensures smooth transitions and prevents unnecessary restarts. The result is a more immersive and responsive audio experience that matches the game’s pacing and excitement.

## Bug Fix: Scoring Consistency
During this session, a subtle bug in the scoring logic was also addressed. The calculation of the absolute value for the moneyline in the `update_scoring` function is now performed after the player’s moneyline is determined, ensuring the correct value is always used for both underdog and favorite scenarios. This fix guarantees that the risk/reward system works as intended, providing fair and accurate results for every race outcome.

## Code Quality and Maintenance
Alongside these features, the codebase saw minor cleanups and improved organization, especially around initialization and state management. These changes lay the groundwork for future enhancements and make the project easier to maintain.

With these updates and fixes, Blob Race continues to grow in personality and polish, offering players a more engaging and delightful experience from the very first screen.
