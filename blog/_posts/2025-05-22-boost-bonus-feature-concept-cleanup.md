---
layout: blog
title: "Boost Bonus Feature \\u2014 From Concept to Cleanup"
date: 2025-05-22
---

# May 22, 2025: Boost Bonus Feature \\u2014 From Concept to Cleanup

The journey of the boost bonus feature has been a multi-step process, evolving from a simple idea into a polished and integral part of Blob Race’s gameplay. Here’s a look back at the work that went into designing, implementing, and refining this system:

## Initial Concept and Implementation
The boost bonus was introduced to add a layer of strategy and excitement to each race. The idea: the slower blob should get a compensatory boost, making races more competitive and less predictable. Early on, I created the `boost_meter` table to track which blob was fastest and to store a bonus value based on the speed gap between the two blobs. The `calculate_boost_bonus` function was written to compute this bonus, using the percentage difference between blob speeds to determine how much extra boost the underdog would receive.

## Integrating With Player and Opponent
To make the system work in-game, I added `player_boost` and `opponent_boost` tables, each with their own `meter` fields. The `boost_balance` function was responsible for distributing the base boost and any bonus to the correct racer, depending on which blob the player selected and which was fastest. This logic ensured that the underdog always started with a little extra in the tank.

## Redundancy and Refactoring
As the feature grew, I noticed redundancy between `boost_meter.player`/`opponent` and `player_boost.meter`/`opponent_boost.meter`. This overlap made the code harder to follow and maintain. Today, I refactored the code to remove the redundant fields, updating all logic to use only `player_boost.meter` and `opponent_boost.meter`. The `boost_balance` function was streamlined, and initialization logic was cleaned up to ensure a consistent and bug-free start to every race.

## The Result
The boost bonus system now works seamlessly, making every race feel dynamic and fair. The codebase is cleaner, easier to maintain, and ready for future enhancements. This feature has added a new layer of depth to Blob Race, and I’m excited to see how it shapes player strategies going forward!
