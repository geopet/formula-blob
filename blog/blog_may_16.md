# May 16, 2025: Race Odds and UI Transparency

Today’s development focused on making Blob Race more transparent and engaging for players by surfacing the underlying race mechanics and odds.

The most notable addition is the new race odds system. Now, when the game starts, each blob is assigned a random speed, and the odds of each blob winning are calculated and displayed. Players can see not only the speed of each blob but also their expected finish times and odds, making the selection process more strategic and exciting. This change brings a new layer of depth to the game, allowing players to make more informed choices and adding a sense of anticipation to every race.

To support this, the UI was updated to show each blob’s speed directly on the selection screen, and log messages now provide real-time feedback about odds and expected times as players make their choices. The codebase was also refactored to introduce a dedicated `race_odds` table and helper functions, streamlining the logic for calculating and displaying these new features.

With these improvements, Blob Race now offers a more transparent and interactive experience, giving players insight into the race’s inner workings and making every decision count. Stay tuned for more enhancements as the game continues to evolve!
