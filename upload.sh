#!/usr/bin/env bash

# Helper script that copies files to the server.
# You need to have authenticated access to the server via SSH to use this.

rsync -rav -e ssh \
--exclude .git/ --exclude *.sh --exclude README.md \
./ \
root@andrewlalis.com:/var/www/andrewlalis.com/html
