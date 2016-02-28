#!/bin/sh
zip -r monsoon.zip src haxelib.json README.md -x "*/\.*"
haxelib submit monsoon.zip
rm monsoon.zip 2> /dev/null