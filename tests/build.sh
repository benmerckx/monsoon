#!/bin/bash
cd "$(dirname "$0")"
haxe tests.hxml
npm install --silent