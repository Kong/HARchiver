harchiver
===================

Lightweight analytics layer for apianalytics.com

Made to be portable, fast and transparent. It lets HTTP/HTTPS traffic through and streams datapoints to apianalytics.com.

## Install

```
wget https://github.com/SGrondin/harchiver/releases/download/v1.0.1/harchiver.tar.gz
tar xzvf harchiver.tar.gz
cd release
```

There's nothing else to do.

Run `./harchiver -help` for instructions.

The program needs a port number to listen to and your Service-Token. `./harchiver <PORT> <SERVICE-TOKEN>`. If a Service-Token isn't provided on the command line, then the HTTP header `Service-Token` needs to be set for every request.

Other command line options include `-https <PORT>` to add HTTPS support. In that case, the files `key.cert` and `cert.pem` need to be in the same directory as the harchiver.

There's also `-debug` to output the generated data on-the-fly.

If the program reports a GLIBC error, it's most likely because your Linux distribution is very old. Please open a Github Issue if the program doesn't start correctly.

### Libraries

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/).

This project ships with a compiled library of ZeroMQ, more specifically, the libzmq.so.4 file. As required by the LGPL license, you have been made aware that you are free to download and replace it with your own from the [official website](http://zeromq.org/intro:get-the-software).

## Compiling

It's recommended to simply use the provided binaries, but here are the instructions to compile it from scratch. It's not for the faint of heart.

####1- Acquire OPAM

Check if your Linux distribution offers OPAM 1.2 in `yum` or `apt-get`. If it does, install it and go to step 2. Otherwise, check if your distribution offers OCaml 4. If it does, install it and go to Step 1.2, if it doesn't, go to Step 1.1.

####1.1- Install OCaml 4.02.0 from source

`git clone` https://github.com/ocaml/ocaml. Checkout version 4.02.0 and follow the instructions in the INSTALL file. Go to Step 1.2.

####1.2- Install OPAM 1.2.0 from source

`git clone` https://github.com/ocaml/opam. Checkout version 1.2.0 and follow the instructions in the README.md file carefully. You'll have to run `make ext-lib` when instructed to. Go to Step 2.

####2- Install an OPAM-managed version of OCaml 4.02.0

This is necessary for some of the dependencies. Run `opam init`, then `opam switch 4.02.0`.

####3- Install ZMQ

Go to http://zeromq.org/intro:get-the-software and download the latest 4.0.x release POSIX tarball. Then scroll and follow the instructions in the `To build on UNIX-like systems` section.

####4- Install the dependencies for Harchiver.

`apt-get install libssl-dev zlib1g-dev` (or `yum`).

Run `opam install core lwt ssl cohttp lwt-zmq atdgen utop`. If it fails, try reinstalling ZMQ and make sure that you followed all the instructions carefully and have all the dependencies listed on the ZMQ page, then try again.

####5- Build it

You are now ready to compile the program. Run `./build.sh` in the Harchiver directory. If everything went fine until this point you'll see a `harchiver` file in the directory. Congrats!

