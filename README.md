# ThreshBuff

This package will show temporary buffs and debuffs for your character and how
long before they will expire.

* Buffs are in green
* Debuffs are in red
* Handicaps are in purpl-y-lilac-y colour

ThreshBuff also installs [Helper](https://github.com/gesslar/Helper), which
formats the `/tbuff` help.

## Commands

| Command | What it does |
| --- | --- |
| `/tbuff` | List the commands. |
| `/tbuff buff [<colour>\|default]` | Set the colour for buff names (default `forest_green`). |
| `/tbuff debuff [<colour>\|default]` | Set the colour for debuff names (default `indian_red`). |
| `/tbuff affliction [<colour>\|default]` | Set the colour for affliction names (default `medium_orchid`). |
| `/tbuff time [<colour>\|default]` | Set the colour for the times (default `grey`). |
| `/tbuff palette` | Show the Mudlet colour names you can use. |
| `/tbuff reset` | Put the window back on the left at its default size. |

Colours are Mudlet colour names. With no colour given, each shows the current
one. Your choices are remembered between sessions and reinstalls.

## License

ThreshBuff is released under the [0BSD](https://opensource.org/license/0bsd).
