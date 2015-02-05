#!/usr/bin/env bash

./scripts/build.sh

patchelf --set-rpath '$ORIGIN/lib/' harchiver
cp harchiver release/
cp LICENSE release/
cp INSTALL release/
cp README.md release/
cp QUICKSTART.md release/
rm -r release/src
cp -R src release/src
tar czvf harchiver.tar.gz release/
