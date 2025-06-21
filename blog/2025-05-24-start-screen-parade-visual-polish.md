---
layout: blog
title: "Start Screen Parade and Visual Polish"
date: 2025-05-24
---

# May 24, 2025: Start Screen Parade and Visual Polish

Today’s update brings a burst of personality to Blob Race with a brand new animated start screen parade, along with several visual and code quality improvements.

## Animated Blob Parade
The most eye-catching addition is the animated blob parade on the start screen. Now, when you launch the game, a colorful procession of blobs marches endlessly across the screen, each with its own sprite, flip, and subtle vertical bob. To make the parade feel lively and unique every time, the code ensures that no two consecutive blobs share the same sprite, and each blob gets a random flip for extra variety.

The parade is implemented as a seamless loop: as blobs scroll off the left edge, they reappear on the right, creating a continuous, never-ending march. This was achieved by calculating the total parade length and drawing each blob a second time, offset by the full parade width, whenever it leaves the visible area. The result is a smooth, polished animation that sets the tone for the game.

## Cleaner Initialization Logic
To support the new parade, the initialization code was refactored. Blob sprites are now chosen with care to avoid repetition, and the parade’s data structure is more robust. This not only improves the visual experience but also makes the code easier to extend for future features.

## Visual Flare and Polish
Alongside the parade, the start screen received additional visual tweaks, including improved color cycling and sprite handling. These changes make the game’s first impression more engaging and professional.

## Looking Ahead
With the start screen parade in place, Blob Race feels more alive and inviting. The groundwork is now set for further polish and new features that will continue to enhance the game’s charm and playability.
