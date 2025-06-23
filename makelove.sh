#!/usr/bin/env bash

# make love file
zip -9 -r SOUS-DISC-GAMEJAM-WINTER.love \
conf.lua \
configuration.lua \
death.lua \
game.lua \
helper.lua \
images/ \
main.lua \
menu.lua \
pause.lua \
person.lua \
push.lua \
ui.lua \
state.lua \
sound-fx/

mv SOUS-DISC-GAMEJAM-WINTER.love output/

# make html game
# you need https://github.com/Davidobot/love.js
cd build-stuff/
pnpx love.js --title "SOUS-DISC-GAMEJAM-WINTER" ../output/SOUS-DISC-GAMEJAM-WINTER.love ../output/html
zip -r SOUS-DISC-GAMEJAM-WINTER-HTML.zip ../output/html/*
mv SOUS-DISC-GAMEJAM-WINTER-HTML.zip ../output/

# make exe
# https://love2d.org/wiki/Game_Distribution
cat love.exe ../output/SOUS-DISC-GAMEJAM-WINTER.love > love-11.5-win64/SOUS-DISC-GAMEJAM-WINTER.exe
zip -r SOUS-DISC-GAMEJAM-WINTER.zip love-11.5-win64/
mv SOUS-DISC-GAMEJAM-WINTER.zip ../output/
