#!/bin/bash
cd "$(dirname "$0")"
set -e
haxe tests.hxml
npm install --silent
node index.js