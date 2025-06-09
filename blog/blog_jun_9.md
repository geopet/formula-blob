# June 9, 2025: Boost Balance, Logging, and UI Polish

The past week has been all about refining the core mechanics and player experience in Blob Race. With a focus on boost balance, improved logging, and UI clarity, the game now feels more responsive, fair, and fun to play.

## Boost Balance Overhaul

A major highlight is the complete overhaul of the boost bonus and strength calculation logic. The boost system is now simpler and more transparent: the bonus is always set as a direct function of the speed gap, and the strength calculation is streamlined for consistency. This not only makes the code easier to maintain but also ensures that races feel balanced and competitive, regardless of which blob you choose.

## Debug Logging Improvements

To aid in development and future tuning, a new `quick_log` table was introduced. This allows for easy, targeted debug output of key boost variables like scale and bonus. The logging system itself has been refactored for clarity, and logging is now off by default for a cleaner player experience.

## UI and Scoring Display

The race countdown and scoring UI have both received polish. The countdown sequence is now more visually engaging, and the scoring display during blob selection and after races is clearer, helping players understand the risk and reward of their choices at a glance.

## Audio and Quality of Life

A new audio mute feature lets players toggle music on and off with a single button press, making the game more accessible in different play environments.

## Under the Hood

Much of the recent work has focused on code quality: refactoring boost logic, consolidating logging, and improving the structure of player and opponent boost tables. These changes make the codebase more robust and ready for future features.

---

With these updates, Blob Race continues to evolve into a more polished, strategic, and enjoyable experience. The boost system is fairer, the UI is clearer, and the code is cleaner—setting the stage for even more exciting features to come!
