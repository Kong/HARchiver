#!/usr/bin/env bash

# For compile.sh
rm *.cmi &> /dev/null
rm *.cmo &> /dev/null
rm *.cmx &> /dev/null

# For build.sh
pushd src &> /dev/null
rm har_*.ml* &> /dev/null
rm -r _build
popd &> /dev/null
