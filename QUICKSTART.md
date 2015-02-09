API Analytics offers a free cloud proxy to quickly get data into our system. Our cloud proxy is running the same open-source proxy that you can [install on your own servers](https://github.com/Mashape/HARchiver) for added security and performance. 

### Cloud Proxy

The public proxy is available at `proxy.apianalytics.com:15000` for HTTP and `proxy.apianalytics.com:15001` for HTTPS. Don't forget to set the required `Host` and `Service-Token` headers. The optional `X-Upstream-Protocol` Header can be set to `HTTP` or `HTTPS` which will override the protocol when connecting upstream.

Here is an example of making request through the cloud proxy:

```bash
curl -H "Host: httpbin.org" -H "Service-Token: SERVICE_TOKEN" http://proxy.apianalytics.com:15000/get
```

### On-Premise

Check out the [HARchiver on GitHub](https://github.com/Mashape/HARchiver) which has all the documentation on installing and using the proxy on-premise. For API Creators it's also possible to use as a [reverse proxy](https://github.com/Mashape/HARchiver#for-api-creators-reverse-proxy) with the `-reverse` option.
