# May 23, 2025: Moneyline Scoring and UI Improvements

Today’s development session brought a major update to Blob Race’s scoring system and user interface, making the game’s risk/reward mechanics more transparent and engaging for players.

## Moneyline-Style Scoring
The biggest change was the implementation of a true moneyline-style scoring system, inspired by sports betting. Now, when you choose your blob, the game calculates a moneyline based on each blob’s probability of winning. If you pick the underdog (positive moneyline), you risk 100 points for a chance to win the moneyline value. If you pick the favorite (negative moneyline), you risk the absolute value of the moneyline for a chance to win 100 points. This change rewards bold choices and makes every race feel more strategic.

The `update_scoring` function was refactored to handle these scenarios, ensuring that both wins and losses are scored according to the selected blob’s moneyline. The logic is now much closer to real-world betting, and the code is easier to follow and maintain.

## UI Enhancements: Clearer Risk and Reward
To help players make informed decisions, the UI in the blob selection screen now displays the exact risk and reward for each blob. The labels under each blob show the amount you risk and the potential reward, updating dynamically based on the calculated moneylines. This makes the game’s strategy more accessible and helps players understand the consequences of their choices.

## Code Quality and Documentation
Alongside these gameplay and UI changes, I added comments to key functions like `win_probability_to_moneyline` to clarify the math behind the moneyline calculation. This should make future tweaks and maintenance much easier.

With these updates, Blob Race now offers a deeper, more transparent, and more rewarding experience for players who enjoy a bit of risk and strategy. Next up: more polish and maybe some new surprises for the racers!
