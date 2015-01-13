#!/usr/bin/env bash

./clean.sh

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

rm -r _build

corebuild \
	-tag debug \
	-pkg lwt \
	-pkg lwt.syntax \
	-pkg cohttp.lwt \
	-pkg lwt-zmq \
	-pkg atd \
	-pkg atdgen \
	-pkg ZMQ \
	main.native

cp main.native harchiver
rm main.native

./clean.sh
