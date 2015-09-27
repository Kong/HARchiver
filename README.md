# HARchiver

> for more information on Mashape Galileo, please visit [apianalytics.com](https://www.apianalytics.com)

## About

HARchiver is a proxy made to be portable, fast and transparent, it takes incoming HTTP/HTTPS calls and routes them to their final destination, collecting stats in the background without slowing down the request itself.

## Cloud Usage

We offer a free, public HARchiver cloud proxy available at `proxy.analytics.mashape.com`, operating on port `80` for HTTP, and port `443` for HTTPS. 

Make sure to send the `Mashape-Service-Token` header to indicate where to route your logs.

**Notes:**

- By default, requests are proxied on the same protocol they were received. To override that, send the header `Mashape-Upstream-Protocol` with the values `HTTP` or `HTTPS`. That makes it possible to query HTTPS-only APIs without enabling HTTPS mode in `HARchiver`.

- There's also the `Mashape-Host-Override` header for use when the `Host` header cannot be set, such as in browser XmlHttpRequest *(AJAX)*.

## On-premises Installation

### Linux *(For OSX and Windows use [Docker](#docker))*

Grab the [latest release](https://github.com/Mashape/HARchiver/releases), then follow the instructions below:

```sh
wget https://github.com/Mashape/harchiver/releases/download/[VERSION]/harchiver.tar.gz
tar xzvf harchiver.tar.gz
cd release
./harchiver
```

- If the program reports a GLIBC error on startup, please [open a Github Issue](https://github.com/Mashape/HARchiver/issues).
- If you expect massive load, [up the server's `ulimit`](http://www.cyberciti.biz/faq/linux-increase-the-maximum-number-of-open-files/)

### Docker

#### HTTP only

The only thing needed is to create a container with the correct port forwarding and [command-line options](#options) from the image.

```sh
# Download the image
docker pull mashape/harchiver

# Then make a container from it
docker run -p 15000:15000 --name="harchiver_http" mashape/harchiver
# or with some options:
docker run -p 15000:15000 --name="harchiver_http" mashape/harchiver /release/harchiver 15000 SERVICE_TOKEN
```

There's now a container named `harchiver_http` that can be started easily with `docker start harchiver_http`. That container can be removed and recreated from the `mashape/harchiver` image easily to change the [command-line options](#options).

#### With HTTPS

The certificate and key must be copied into a new image based on the `mashape/harchiver` image.

On boot2docker, don't forget to run `$(boot2docker shellinit)`.

```sh
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

### From Source

[Instructions in this file](INSTALL.md)

## Usage

### For API Consumers *(proxy)*

You can use HARchiver as a proxy layer between your application and *any* local or remote API server.

```
                          ┌─────────────┐                 
                          │ Private API │                 
                          └─────────────┘                 
                                 ▲                        
                           ┌─────┘     ┌─────────────────┐
                           │        ┌─▶│ API Provider #1 │
 ┌─────────────┐    ┌─────────────┐ │  └─────────────────┘
 │ Application │───▶│  HARchiver  │─┤  ┌─────────────────┐
 └─────────────┘    └─────────────┘ └─▶│ API Provider #2 │
                                       └─────────────────┘
```

Start HARchiver on port `15000` with your Mashape Analytics Service Token:

```sh
./harchiver 15000 SERVICE_TOKEN
```

Now you can send requests through the HARchiver using the `Host` header, here's an example of making a GET request to `http://mockbin.org/request` through the HARchiver proxy:

```sh
curl -H "Host: mockbin.org" -H "Mashape-Upstream-Protocol: HTTP" http://127.0.0.1:15000/get
```

That's it, your data is now available on [Mashape Analytics](https://www.apianalytics.com)!

### For API Creators *(reverse proxy)*

To capture *all* incoming traffic to your API, start HARchiver on port `15000` in reverse-proxy mode with your Mashape Analytics Service Token:

```
 ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
 │The Internet │────▶│  HARchiver  │────▶│  Your API   │
 └─────────────┘     └─────────────┘     └─────────────┘
```

```sh
./harchiver 15000 -reverse 10.1.2.3:8080 SERVICE_TOKEN
```

In this example, `10.1.2.3:8080` is the location of your API. All incoming requests will be directed there.

HARchiver can do SSL termination itself (`-https` option), but if you're already using nginx to do so, you should simply make nginx proxy to HARchiver which proxies to your application. *See the network diagram below*

```
                                       ┌─────────────┐       ┌───────────┐
                                    ┌─▶│  HARchiver  │──────▶│  API #1   │
                    ┌─────────────┐ │  └─────────────┘       └───────────┘
 ┌─────────────┐    │    nginx    │ │  ┌─────────────┐       ┌───────────┐
 │The Internet │───▶│   HAproxy   │─┼─▶│  HARchiver  │──────▶│  API #2   │
 └─────────────┘    │     SSL     │ │  └─────────────┘       └───────────┘
                    └─────────────┘ │  ┌─────────────┐       ┌───────────┐
                                    └─▶│  HARchiver  │──────▶│  API #3   │
                                       └─────────────┘       └───────────┘
```

*The SSL termination (aka decryption) can be either done in nginx/HAproxy or HARchiver.*

**Note:**

- HARchiver uses only 20Mb of RAM and should be located on the same machine as your API Servers to reduce latency and simplify configuration.

- if running multiple services per ip, You can inspect the `Host` header in your code to determine what service the client requested, if necessary, or if you wish to limit HARchiver to a specific service / host, use the host name instead of an IP in the previous step.

```sh
curl http://127.0.0.1:15000/some/url/on/the/api
```

That's it, your data is now available on [Mashape Analytics](https://www.apianalytics.com)!

## Options

```sh
harchiver PORT [SERVICE_TOKEN]
```

- Without `SERVICE_TOKEN` the HTTP header `Mashape-Service-Token` must be set on every request.

### Optional Flags

| Flag              | Description                                                                                          | Default |
| ----------------- | ---------------------------------------------------------------------------------------------------- | ------- |
| `-c NB`           | maximum number of concurrent requests.                                                               | `500`   |
| `-debug`          | output the generated data on-the-fly                                                                 | `-`     |
| `-https PORT`     | add HTTPS support. *The files `key.cert` & `cert.pem` need to be in the same directory as HARchiver* | `-`     |
| `-replays`        | enable replays by sending the body of the requests in the ALF                                        | `-`     |
| `-reverse target` | start in reverse-proxy mode                                                                          | `-`     |
| `-t TIMEOUT`      | set remote server response timeout in seconds.                                                       | `6`     |
| `-version`        | displays the version number                                                                          |         |
| `-help`           | displays usage instructions                                                                          |         |

## Copyright and license

Copyright Mashape Inc, 2015.

Licensed under [the MIT License](https://github.com/Mashape/HARchiver/blob/master/LICENSE)
