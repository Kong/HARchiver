#!/usr/bin/env bash

./scripts/clean.sh

pushd src &> /dev/null

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

corebuild \
	-tag debug \
	-no-links \
	-no-hygiene \
	-pkg lwt \
	-pkg lwt.preemptive \
	-pkg lwt.syntax \
	-pkg ZMQ \
	-pkg lwt-zmq \
	-pkg cohttp.lwt \
	-pkg dns.lwt \
	-pkg atd \
	-pkg atdgen \
	-pkg re.pcre \
	-pkg ctypes \
	-pkg ctypes.foreign \
	main.native

gcc -c -lzmq -I.. ../tzmq.c -o tzmq.o

# With -no-links:
ocamlfind ocamlopt -o ../h2 -cclib -Wl,-E,-lzmq -g -linkpkg -thread -syntax camlp4o -package core,lwt,lwt.preemptive,lwt.syntax,ZMQ,lwt-zmq,cohttp.lwt,dns.lwt,atd,atdgen,re.pcre,ctypes,ctypes.foreign -I _build tzmq.o har_t.cmx har_j.cmx regex.cmx settings.cmx http_utils.cmx archive.cmx cache.cmx network.cmx proxy.cmx main.cmx

popd &> /dev/null
