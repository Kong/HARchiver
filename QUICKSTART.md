# Proxy

API Analytics offers a free cloud proxy to quickly get data into our system. Our cloud proxy is running the same open-source proxy that you can [install on your own servers](#on-premise) for added security and performance. 

### Cloud Proxy

The public proxy is available at `104.236.197.123:15000`. 

Don't forget to set the required `Host` and `Service-Token` headers. The optional `X-Upstream-Protocol` Header can be set to `HTTP` or `HTTPS` which overrides the protocol when connecting upstream.

Here is an example of making request through the proxy:

```bash
curl -H "Host: httpbin.org" -H "Service-Token: SERVICE_TOKEN" http://104.236.197.123:15000/get
```

### On-Premise

Check out the [HARchiver on GitHub](https://github.com/Mashape/HARchiver) which has all the documentation on installing and using the proxy on-premise. For API Creators it's also possible to use as a [reverse proxy]() with the `-reverse` option.
