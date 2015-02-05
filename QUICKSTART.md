We now offer also a free public proxy at `104.236.197.123:15000` in addition to the on-premise option. Don't forget to set the `Service-Token` header. The `X-Upstream-Protocol` (set to HTTP or HTTPS) overrides the default protocol to connect to the upstream.
```bash
curl -H "Host: httpbin.org" -H "Service-Token: SERVICE_TOKEN" http://104.236.197.123:15000/get
```
That called `http://httpbin.org/get` through the proxy. That's it, your data is now available on [APIAnalytics.com](http://www.apianalytics.com)!

*To set up your own HARchiver proxy, check out the [repo on Github](https://github.com/APIAnalytics/HARchiver).*
