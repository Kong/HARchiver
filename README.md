# HARchiver

Universal lightweight proxy for apianalytics.com that was made to be portable, fast and transparent.

We now have a free public HARchiver server available at 104.236.197.123:15000. Make sure to send the `Service-Token` header.

## Quick Start

First get your [APIAnalytics.com](http://www.apianalytics.com) service token and [install HARchiver](#installation).

HARchiver is a proxy, it takes incoming HTTP/HTTPS calls and routes them to their final destination, collecting stats in the background without slowing down the request itself.

**Note:** By default, requests are proxied on the same protocol they were received. To override that, send the header `X-Upstream-Protocol` with the values HTTP or HTTPS. That makes it possible to query HTTPS-only APIs without enabling HTTPS mode in HARchiver.

[See the network diagram](#reverse-proxy)

### For API Consumers *(proxy)*

You can use HARchiver as a proxy layer between your application and *any* local or remote API server. *([see network diagram](#proxy))*

Start HARchiver on port 15000 with your API analytics service token:

```shell
./harchiver 15000 SERVICE_TOKEN
```

Now you can send requests through the HARchiver using the `Host` header:

```shell
curl -H "Host: httpbin.org" http://127.0.0.1:15000/get
```

That called `http://httpbin.org/get` through HARchiver. That's it, your data is now available on [APIAnalytics.com](http://www.apianalytics.com)!

### For API Creators *(reverse proxy)*

To capture *all* incoming traffic to your API, start HARchiver on port 15000 in reverse-proxy mode with your API analytics service token:

```shell
./harchiver 15000 -reverse 10.1.2.3:8080 SERVICE_TOKEN
```

In this example, `10.1.2.3:8080` is the location of your API. All incoming requests will be directed there.

HARchiver can do SSL termination itself (`-https` option), but if you're already using nginx to do so, you should simply make nginx proxy to HARchiver which proxies to your application. [See the network diagram](#reverse-proxy)

**Note:** if running multiple services per ip, You can inspect the `Host` header in your code to determine what service the client requested, if necessary, or if you wish to limit HARchiver to a specific service / host, use the host name instead of an IP in the previous step.

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
| `-https PORT`     | add HTTPS support. *The files `key.cert` & `cert.pem` need to be in the same directory as HARchiver* |
| `-replays`        | enable replays by sending the body of the requests in the ALF                                        |
| `-reverse target` | start in reverse-proxy mode                                                                          |
| `-t TIMEOUT`      | set remote server response timeout. *(default: 6 seconds)*                                           |
| `-version`        | displays the version number                                                                          |
| `-help`           | displays usage instructions                                                                          |

## Installation

### Linux *(For OSX and Windows use [Docker](#docker))*

```shell
wget https://github.com/Mashape/harchiver/releases/download/v1.6.0/harchiver.tar.gz
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

[Instrictions in this file](INSTALL)

## Network Diagrams

###### Proxy

<pre><code>
                                         +-------------+
                                    +--->| Private API |
                    +-----------+   |    +-------------+
+-------------+     |           +---+    +-----------------+
| Application +---->| HARchiver +------->| API Provider #1 |
+-------------+     |           +---+    +-----------------+
                    +-----------+   |    +-----------------+
                                    +--->| API Provider #2 |
                                         +-----------------+
<code></pre>

###### Reverse Proxy

<pre><code>
                     +-----------+     +-----------------+
+--------------+     |           |     |                 |
| The Internet +---->| HARchiver +---->| Your API Server |
+--------------+     |           |     |                 |
                     +-----------+     +-----------------+
<code></pre>

###### Reverse Proxy *(with additional proxy layers)*

*The SSL termination (aka decryption) can be either done in nginx/HAproxy or HARchiver.*

HARchiver uses only 20Mb of RAM and should be located on the same machine as your API Servers to reduce latency and simplify configuration.

<pre><code>
                                           +-----------+     +--------------------+
                                     +---->| HARchiver +---->| Your API Server #1 |
                     +-----------+   |     +-----------+     +--------------------+
+--------------+     | nginx     +---+     +-----------+     +--------------------+
| The Internet +---->| HAproxy   +-------->| HARchiver +---->| Your API Server #2 |
+--------------+     | ssl       +---+     +-----------+     +--------------------+
                     +-----------+   |     +-----------+     +--------------------+
                                     +---->| HARchiver +---->| Your API Server #3 |
                                           +-----------+     +--------------------+
<code></pre>
