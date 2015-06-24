SHELL := /bin/bash
all: build

cert:
	# generate key
	openssl genrsa -out server.key 1024
	# strip password
	mv server.key server.key.pass
	openssl rsa -in server.key.pass -out server.key
	# generate csr
	openssl req -new -key server.key -out server.csr
	# generate self singe certificate with csr
	openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt
	rm server.csr server.key.pass
	mv server.key key.pem
	mv server.crt cert.pem

clean:
	@# For compile.sh
	@rm -f *.cmi
	@rm -f *.cmo
	@rm -f *.cmx

	@# For build.sh
	@pushd src &> /dev/null && \
	rm -f har_*.ml* && \
	rm -rf _build

compile: clean
	@pushd src &> /dev/null && \
	\
	atdgen -t -j-std har.atd && \
	atdgen -j -j-std har.atd && \
	\
	ocamlfind ocamlc -c har_t.mli -package atdgen && \
	ocamlfind ocamlc -c har_j.mli -package atdgen && \
	ocamlfind ocamlc -c har_t.ml -package atdgen && \
	ocamlfind ocamlc -c har_j.ml -package atdgen && \
	\
	ocamlfind ocamlc -c regex.mli -package re.pcre && \
	ocamlfind ocamlc -c regex.ml -thread -package core,re.pcre && \
	\
	ocamlfind ocamlc -c settings.mli -thread -package core,cohttp.lwt && \
	ocamlfind ocamlc -c settings.ml -thread -package core,cohttp.lwt && \
	\
	ocamlfind ocamlc -c http_utils.mli -package cohttp.lwt && \
	ocamlfind ocamlc -c http_utils.ml -thread -package core,cohttp.lwt && \
	\
	ocamlfind ocamlc -c archive.mli -package cohttp.lwt && \
	ocamlfind ocamlc -c archive.ml -thread -package core,cohttp.lwt && \
	\
	ocamlfind ocamlc -c cache.mli -thread -package core,lwt && \
	ocamlfind ocamlc -c cache.ml -thread -package core,lwt && \
	\
	ocamlfind ocamlc -c network.mli -thread -package core,cohttp.lwt,lwt-zmq && \
	ocamlfind ocamlc -c network.ml -thread -package core,cohttp.lwt,lwt-zmq,dns && \
	\
	ocamlfind ocamlc -c proxy.mli -package lwt && \
	ocamlfind ocamlc -c proxy.ml -thread -package core,lwt.syntax,cohttp.lwt,lwt-zmq -syntax camlp4o && \
	\
	ocamlfind ocamlc -c main.ml -thread -package core,lwt && \
	\
	mv *.cm* .. && \
	rm har_*.ml* && \
	echo "Success"

build: clean
	@pushd src &> /dev/null && \
	\
	atdgen -t -j-std har.atd && \
	atdgen -j -j-std har.atd && \
	\
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
		main.native && \
	\
	cp main.native ../harchiver && \
	rm main.native && \
	echo "Success"

package: build
	$(MAKE) clean
	patchelf --set-rpath '$$ORIGIN/lib/' harchiver
	cp harchiver release/
	cp LICENSE release/
	cp INSTALL.md release/
	cp README.md release/
	cp QUICKSTART.md release/
	rm -r release/src
	cp -R src release/src
	tar czvf harchiver.tar.gz release/

docker:
	sudo docker build --tag="mashape/harchiver:latest" .
