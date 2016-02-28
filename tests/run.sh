#!/bin/bash
cd "$(dirname "$0")"
haxe tests.hxml

docker-compose up -d

neko bin/neko/index.n &
NEKO_PID=$!
./bin/cpp/Run &
CPP_PID=$!
node bin/node/index.js &
NODE_PID=$!

npm install --silent
node index.js

kill $NEKO_PID
kill $CPP_PID
kill $NODE_PID
docker-compose stop && echo "y" | docker-compose rm