#!/usr/bin/env bash

./build.sh

patchelf --set-rpath '$ORIGIN/' analytics-harchiver
cp analytics-harchiver release/
cp LICENSE release/
cp README.md release/
tar czvf analytics-harchiver.tar.gz release/

