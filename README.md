# Currency-Counter-Addon
Add-on for Lailloken's Exile-UI that counts currency you spend in Path of Exile 1/2

# Installation
Requires at least v1.63.10 of Exile-UI (https://github.com/Lailloken/Exile-UI/releases)
1. In main Exile-UI folder create "add-ons" folder
2. Create "loader" file (without extension)
3. Open "loader" in notepad and paste "#Include *i add-ons\currency counter\currency-counter-module.ahk" (without citations)
4. Download newest release of this repo https://github.com/BocikPG/Currency-Counter-Addon/releases
5. Create folder named "Currency Counter" in "add-ons" folder
6. Put unzipped files inside "Currency Counter" folder
7. It should look like this:

```text
.
├── Exile-UI/
│   ├── add-ons/
│   │   └── Currency Counter
│   │   │   └── currency-counter-module.ahk
│   │   │   └── json.info
│   │   │   └── ...
│   │   └── loader
│   ├── data
│   ├── exports
│   ├── ...
│   └── Exile UI.ahk
```
![Screenshot](img/md/folder%20add-ons.png)
![Screenshot](img/md/folder%20currency%20counter.png)

8. Launch/restart Exile-UI
9. In game open Exile-UI settings
10. In add-ons section hit ENABLE button
11. Warning about potentially malicious content will pop up, hit ok
12. If needed enable "Currency Counter" and restart the app
13. You can use ⚙ symbol to access add-on settings

At the end it should look like this:

![Screenshot](img/md/settings%20addon-menu.png)

# Usage

If module is enabled the black bar on the bottom of the screen will appear.
![Screenshot](img/md/bar.png)

On currency pick-up (right-click on valid currency item) name of the currency will show up on the bar.

![Screenshot](img/md/bar%20orb.png)
![Screenshot](img/md/fossil%20example.png)

If currency is correctly applied it will create/increase it's record in current session.
If currency has failed to apply for whatever reason it's not counted.

Omens are counted on being consumed automatically.

# Table view
![Screenshot](img/md/table%20ninja%20+%20normal.png)

SSF mode:

![Screenshot](img/md/table%20ssf.png)

For used currency data view click the black bar.
New window will pop up. Window contains of few parts:
- sessions management row:
- - click session name to pick as current one (current one is white one)
- - create new session with big "+" button
- current session management:
- - you can change name of the session, delete it
- - if not in ssf mode, you can update ninja prices (if enabled) and div/chaos div/exalt ratio for calculation of the whole cost
- table of used currencies in this session
- - table allows to sort (desc/asc) by clicking on label (e.g. Count will show most used currency)
- - white text box allows for filtering by name and adding new field by double-clicking "+" button next to it. Red "X" clears this field
![Screenshot](img/md/table%20only%20fossils.png)
- - "count"/"price" fields can be clicked to enter new value
- - "in" fields can be clicked to change currency type of the price is in (per item)
- - "updated" show when price field was last updated - it changes color based on how long it has been since last change
- - "total" column shows:
- - - total cost of this crafting session - it can be clicked to change display currency type
- - - sum of cost for each individual item (count * price) converted to given currency


# Known limitations
To see updates of used currencies you have to click on bar (even if table view is visible) - this is done due to performance reasons

Changing currency while holding alt applies correct one, but is shows still originally picked up

Very fast spamming doesn't count everything/can decrease count - slow down a bit sir o7

"Base" cannot be inserted as custom currency item (uses "bases")

# Want something changed?
Open an issue https://github.com/BocikPG/Currency-Counter-Addon/issues

If you want you can even implement it and send a PR and have a discussion - unless you are AI Bot...

If you want to talk, hit me up on discord - Lailloken found my tag you should too ;)

# AI discourse
I use AI to generate code. I analyze ALL parts it generated in order to be sure it does it correctly and performant. 

AHK is not my first language of choice and I don't want to change that :D .

# History
Project started as a fork of Exile-UI (https://github.com/BocikPG/Lailloken-UI), to add features like getting prices from trade (later implemented by original repo - not as whole, but happy with his implementation), or module you see today in this form. Whole git history is available on fork's github page. 

I want to believe I was the reason some changes in original repo was done by my "encouragement" including add-ons :v .

# BIG SHOUT-OUT TO LAILLOKEN for working on tool for so many years now
and helping me many times :3