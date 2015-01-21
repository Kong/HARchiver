#!/usr/bin/env bash

./scripts/clean.sh

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

rm -r _build

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
	main.native

cp main.native harchiver
rm main.native

./scripts/clean.sh
