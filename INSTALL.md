*Not recommended for the faint of heart!*

Check out the README for install instructions without having to build it manually.

### 1- Acquire OPAM

Check if your Linux distribution offers OPAM 1.2 in `yum` or `apt-get`. If it does, install it and go to step 2. Otherwise, check if your distribution offers OCaml 4. If it does, install it and go to Step 1.2, if it doesn't, go to Step 1.1.

### 1.1- Install OCaml 4.02.1 from source

`git clone` https://github.com/ocaml/ocaml. Checkout version 4.02.1 and follow the instructions in the INSTALL file. Go to Step 1.2.

### 1.2- Install OPAM 1.2.0 from source

`git clone` https://github.com/ocaml/opam. Checkout version 1.2.0 and follow the instructions in the README.md file carefully. You'll have to run `make ext-lib` when instructed to. Go to Step 2.

### 2- Install an OPAM-managed version of OCaml 4.02.1

This is necessary for some of the dependencies. Run `opam init`, then `opam switch 4.02.1`.

### 3- Install the system dependencies for HARchiver and ZMQ.

For HARchiver:

`apt-get install libssl-dev zlib1g-dev libev-dev aspcud` (or the equivalent packages in `yum`).

For ZMQ:

`sudo apt-get install libtool pkg-config build-essential autoconf automake uuid-dev uuid e2fsprogs`

### 4- Install ZMQ

Go to http://zeromq.org/intro:get-the-software and download the latest 4.0.x release POSIX tarball. Then scroll and follow the instructions in the `To build on UNIX-like systems` section.

### 5- Install the OPAM dependencies for HARchiver:

`opam install core lwt conf-libev ssl cohttp lwt-zmq atdgen dns re utop`.

If it fails, try reinstalling ZMQ and make sure that you followed all the instructions carefully and have all the dependencies listed on the ZMQ page, then try again.

### 6- Build it

You are now ready to compile the program. Run `make` in the Harchiver directory. If everything went fine until this point you'll see a `harchiver` file in the directory. Congrats!

## Libraries

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/).

This project ships with a compiled library of ZeroMQ, more specifically, the libzmq.so.4 file. As required by the LGPL license, you have been made aware that you are free to download and replace it with your own from the [official website](http://zeromq.org/intro:get-the-software).
