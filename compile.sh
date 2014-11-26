#!/usr/bin/env bash

./clean.sh

atdgen -t -j-std har.atd
atdgen -j -j-std har.atd

ocamlfind ocamlc -c har_t.mli -package atdgen
ocamlfind ocamlc -c har_j.mli -package atdgen
ocamlfind ocamlc -c har_t.ml -package atdgen
ocamlfind ocamlc -c har_j.ml -package atdgen

ocamlfind ocamlc -c archive.mli -thread -package core,lwt,cohttp.lwt
ocamlfind ocamlc -c archive.ml -thread -package core,lwt,cohttp.lwt
