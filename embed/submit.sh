#!/bin/sh
zip -r monsoon.zip src haxelib.json extraParams.hxml -x "*/\.*"
haxelib submit monsoon.zip
rm monsoon.zip 2> /dev/null