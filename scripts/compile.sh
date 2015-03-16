#!/usr/bin/env bash

./scripts/clean.sh

pushd src &> /dev/null

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

ocamlfind ocamlc -c har_t.mli -package atdgen
ocamlfind ocamlc -c har_j.mli -package atdgen
ocamlfind ocamlc -c har_t.ml -package atdgen
ocamlfind ocamlc -c har_j.ml -package atdgen

ocamlfind ocamlc -c regex.mli -package re.pcre
ocamlfind ocamlc -c regex.ml -thread -package core,re.pcre

ocamlfind ocamlc -c settings.mli -thread -package core,cohttp.lwt
ocamlfind ocamlc -c settings.ml -thread -package core,cohttp.lwt

ocamlfind ocamlc -c http_utils.mli -package cohttp.lwt
ocamlfind ocamlc -c http_utils.ml -thread -package core,cohttp.lwt

ocamlfind ocamlc -c archive.mli -package cohttp.lwt
ocamlfind ocamlc -c archive.ml -thread -package core,cohttp.lwt

ocamlfind ocamlc -c cache.mli -thread -package core,lwt
ocamlfind ocamlc -c cache.ml -thread -package core,lwt

ocamlfind ocamlc -c network.mli -thread -package core,cohttp.lwt,lwt-zmq,ctypes
ocamlfind ocamlc -c network.ml -thread -package core,cohttp.lwt,lwt-zmq,dns,ctypes

ocamlfind ocamlc -c proxy.mli -package lwt
ocamlfind ocamlc -c proxy.ml -thread -package core,lwt.syntax,cohttp.lwt,lwt-zmq,ctypes -syntax camlp4o

ocamlfind ocamlc -c main.ml -thread -package core,lwt

mv *.cm* ..
rm har_*.ml*

popd &> /dev/null
