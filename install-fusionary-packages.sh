#!/bin/sh

jq -r -c '.[]' < fusionary-packages.json |
while read -r composerPackage
do
    composer require $composerPackage -W
done
