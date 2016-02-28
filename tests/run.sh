#!/bin/bash
cd "$(dirname "$0")"
haxe tests.hxml
docker-compose up -d
sleep 1
curl http://localhost:3000
curl http://localhost:3001
curl http://localhost:3002
curl http://localhost:3003