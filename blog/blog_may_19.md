# May 19, 2025: Match Scoring and Game Over Logic

Today's development brought a new competitive edge to Blob Race with the introduction of match scoring and a proper game over system.

The most significant update is the addition of a scoring system that tracks both the player's and the computer opponent's progress across multiple races. Now, each win or loss adjusts the scores, and the game keeps a tally of wins and losses for both sides. The UI has been updated to display these scores and match results, making each race feel more meaningful and giving players a clear sense of progression.

A new game over condition has also been implemented: when either the player or the opponent reaches 1000 points, the match ends, and the game provides a clear message about the outcome. Players can now see if they've won or lost the match, not just individual races, and are prompted to play again or continue racing as appropriate.

Supporting these features, the codebase now includes helper functions for updating scores, checking for game over, and initializing match state. These changes make the game loop more robust and the gameplay experience more rewarding.

With these improvements, Blob Race now offers a true sense of competition and accomplishment. Stay tuned for more features and polish as the game continues to evolve!
