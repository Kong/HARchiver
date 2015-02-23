API Analytics offers a public cloud proxy that you can send requests through to quickly get data into the system. Our cloud proxy is running the same open-source proxy that you can [install on your own servers](https://github.com/Mashape/HARchiver) for added security and performance or to use as a [reverse proxy](https://github.com/Mashape/HARchiver#for-api-creators-reverse-proxy).

### Cloud Proxy

The cloud proxy is available at `http://proxy.apianalytics.com:15000` for HTTP and `https://proxy.apianalytics.com:15001` for HTTPS. You can use the free cloud proxy by sending it requests with the required `Host` and `Service-Token` headers. An optional `X-Upstream-Protocol` Header can be set to `HTTP` or `HTTPS` which will override the protocol when connecting upstream.

Here's an example of making a GET request to `http://httpconsole.com/status/418/tea` using the cloud proxy:

```bash
curl http://proxy.apianalytics.com:15000/status/418/tea -H "Host: httpconsole.com" -H "Service-Token: SERVICE_TOKEN" 
```

**Note:** In-browser tools such as Postman do not let you override the `Host` header because they rely on XMLHttpRequest.

### On-Premise

Check out the [HARchiver on GitHub](https://github.com/Mashape/HARchiver) which has all the documentation on installing and using the proxy on-premise. For API Creators it's also possible to use as a [reverse proxy](https://github.com/Mashape/HARchiver#for-api-creators-reverse-proxy) with the `-reverse` option.