#!/usr/bin/env bash

./scripts/clean.sh

pushd src &> /dev/null

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

corebuild \
	-tag debug \
	-pkg lwt \
	-pkg lwt.syntax \
	-pkg cohttp.lwt \
	-pkg dns.lwt \
	-pkg lwt-zmq \
	-pkg atd \
	-pkg atdgen \
	-pkg ZMQ \
	-pkg re.pcre \
	main.native

cp main.native ../harchiver
rm main.native

popd &> /dev/null

./scripts/clean.sh
