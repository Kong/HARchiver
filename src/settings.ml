let version = "1.6.1"
let name = "ApiAnalytics HARchiver"

let default_zmq_host = "socket.apianalytics.com"
let default_zmq_port = 5000

let concurrent = 500
let timeout = 6.

let zmq_flush_timeout = 20.

let http_error_wait = 0.5

let resolver_pool = 10
let resolver_timeout = 10. (* Currently unused *)
let resolver_expire = 30.
