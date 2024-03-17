#!/usr/bin/env bash

# Helper script that copies files to the server.
# You need to have authenticated access to the server via SSH to use this.

# First we build the garden pages from the data in the "garden-plant-data.ods"
# spreadsheet (edited via LibreOffice Calc) and the images we've added for each
# plant in ./images/garden.

cd garden-data-gen
dub run
cd ..

# Note: Quite a few files are excluded from being uploaded to the website.
# These are denoted with an "--exclude" parameter.

rsync -rav -e ssh --delete \
--exclude .git/ --exclude *.sh --exclude README.md --exclude *.d --exclude *.ods --exclude garden-data-gen/ \
./ \
root@andrewlalis.com:/var/www/andrewlalis.com/html
