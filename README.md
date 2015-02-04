# HARchiver

Universal lightweight proxy for apianalytics.com that was made to be portable, fast and transparent.

## Quick Start

First get your [APIAnalytics.com](http://www.apianalytics.com) service token and [install HARchiver](#install).

### For API consumers *(proxy)*

Start HARchiver on port 15000 with your API analytics service token:

```shell
./harchiver 15000 SERVICE_TOKEN
```

Now you can send requests through the HARchiver using the `Host` header:

```shell
curl -H "Host: httpconsole.com" http://127.0.0.1:15000/echo
```

That's it, your data is now available on [APIAnalytics.com](http://www.apianalytics.com)!

### For API providers *(reverse proxy)*

Start HARchiver on port 15000 in reverse-proxy mode with your API analytics service token:

```shell
./harchiver 15000 -reverse 10.1.2.3:8080 SERVICE_TOKEN
```

In this example, `10.1.2.3:8080` is the location of your API. All incoming requests will be directed there. You can read the `Host` header to inspect what service the client requested.

```shell
curl http://127.0.0.1:15000/some/url/on/the/api
```

That's it, your data is now available on [APIAnalytics.com](http://www.apianalytics.com)!

## Usage

```shell
harchiver PORT [OPTIONAL_SERVICE_TOKEN]
```

- Without `OPTIONAL_SERVICE_TOKEN` the HTTP header `Service-Token` must be set on every request.

### Optional Flags

| Flag              | Description                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| `-c NB`           | maximum number of concurrent requests. *(default: 500)*                                              | 
| `-debug`          | output the generated data on-the-fly                                                                 |
| `-https PORT`     | add HTTPS support. *The files `key.cert` & `cert.pem` need to be in the same directory as harchiver* |
| `-reverse target` | start in reverse-proxy mode                                                                          |
| `-t TIMEOUT`      | set remote server response timeout. *(default: 6 seconds)*                                           |
| `-version`        | displays the version number                                                                          |
| `-help`           | displays usage instructions                                                                          |

## Installation

### Linux *(For OSX and Windows use [Docker](#docker))*

```shell
wget https://github.com/Mashape/harchiver/releases/download/v1.5.0/harchiver.tar.gz
wget https://github.com/Mashape/harchiver/releases/download/v1.4.2/harchiver.tar.gz
tar xzvf harchiver.tar.gz
cd release
./harchiver
```

If the program reports a GLIBC error on startup, please [open a Github Issue](https://github.com/APIAnalytics/HARchiver/issues).

If you expect massive load, [up the server's `ulimit`](http://www.cyberciti.biz/faq/linux-increase-the-maximum-number-of-open-files/)


### Docker 

#### HTTP only

The only thing needed is to create a container with the correct port forwarding and [command-line options](#usage) from the image.

```shell
# Download the image
docker pull mashape/harchiver

# Then make a container from it
docker run -p 15000:15000 --name="harchiver_http" mashape/harchiver
# or with some options:
docker run -p 15000:15000 --name="harchiver_http" mashape/harchiver /release/harchiver 15000 SERVICE_TOKEN
```

There's now a container named `harchiver_http` that can be started easily with `docker start harchiver_http`. That container can be removed and recreated from the `mashape/harchiver` image easily to change the [command-line options](#usage).

#### With HTTPS

The certificate and key must be copied into a new image based on the `mashape/harchiver` image.

On boot2docker, don't forget to run `$(boot2docker shellinit)`.

```shell
# Download the image
docker pull mashape/harchiver

# Then make a basic container
docker run -p 15000:15000 --name="harchiver_http" mashape/harchiver

# Let it run and switch to a new terminal window
# Remember that the certificate and key MUST be named cert.pem and key.pem
# Copy the certificate and the key into the container
docker exec -i harchiver_http bash -c 'cat > /key.pem' < key.pem
docker exec -i harchiver_http bash -c 'cat > /cert.pem' < cert.pem

# Stop the container
docker kill harchiver_http

# Save it as a new image
docker commit -m "Added https support" harchiver_http harchiver_image_https

# Create a container from it
docker run -p 15000:15000 -p 15001:15001 --name="harchiver_https" harchiver_image_https /release/harchiver 15000 -https 15001 SERVICE_TOKEN
```

## From Source

*Not recommended for the faint of heart!*

### 1- Acquire OPAM

Check if your Linux distribution offers OPAM 1.2 in `yum` or `apt-get`. If it does, install it and go to step 2. Otherwise, check if your distribution offers OCaml 4. If it does, install it and go to Step 1.2, if it doesn't, go to Step 1.1.

### 1.1- Install OCaml 4.02.0 from source

`git clone` https://github.com/ocaml/ocaml. Checkout version 4.02.0 and follow the instructions in the INSTALL file. Go to Step 1.2.

### 1.2- Install OPAM 1.2.0 from source

`git clone` https://github.com/ocaml/opam. Checkout version 1.2.0 and follow the instructions in the README.md file carefully. You'll have to run `make ext-lib` when instructed to. Go to Step 2.

### 2- Install an OPAM-managed version of OCaml 4.02.0

This is necessary for some of the dependencies. Run `opam init`, then `opam switch 4.02.0`.

### 3- Install ZMQ

Go to http://zeromq.org/intro:get-the-software and download the latest 4.0.x release POSIX tarball. Then scroll and follow the instructions in the `To build on UNIX-like systems` section.

### 4- Install the dependencies for HARchiver.

`apt-get install libssl-dev zlib1g-dev libev-dev` (or `yum`).

Run `opam install core lwt conf-libev ssl cohttp lwt-zmq atdgen dns utop`. If it fails, try reinstalling ZMQ and make sure that you followed all the instructions carefully and have all the dependencies listed on the ZMQ page, then try again.

### 5- Build it

You are now ready to compile the program. Run `make` in the Harchiver directory. If everything went fine until this point you'll see a `harchiver` file in the directory. Congrats!

## Libraries

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/).

This project ships with a compiled library of ZeroMQ, more specifically, the libzmq.so.4 file. As required by the LGPL license, you have been made aware that you are free to download and replace it with your own from the [official website](http://zeromq.org/intro:get-the-software).
