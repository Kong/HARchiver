#!/usr/bin/env bash

./scripts/build.sh
./scripts/clean.sh

patchelf --set-rpath '$ORIGIN/lib/' harchiver
cp harchiver release/
cp LICENSE release/
cp INSTALL.md release/
cp README.md release/
cp QUICKSTART.md release/
rm -r release/src
cp -R src release/src
tar czvf harchiver.tar.gz release/
