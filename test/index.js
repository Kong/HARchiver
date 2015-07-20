var fs = require('fs')
var https = require('https')
var sleep = require('sleep')
var request = require('superagent')
var spawn = require('child_process').spawn
var exec = require('child_process').exec
var util = require('util')
var HTTP_PORT = 15555
var HTTPS_PORT = 15556
global.SERVICE_TOKEN = 'defaultServiceToken'
HTTP_TEST = function(method, path, headers, body, cb) {
  var builder = request[method.toLowerCase()](util.format('%s://127.0.0.1:%d/%s', 'http', HTTP_PORT, path))
  for (var h in headers) {
    builder = builder.set(headers[h][0], headers[h][1])
  }
  builder.send(body).end(function(err, result) {
    if (err != null) {
      return cb(err)
    }

    var parsed = JSON.parse(result.res.text)
    cb(err, parsed, result)
  })
}

CURL = function(method, path, headers, body, cb) {
  var H = headers.map(function(h) {
    return util.format('-H "%s: %s"', h[0], h[1])
  }).join(' ')
  exec(util.format('curl -X %s https://127.0.0.1:%d/%s %s -k -d "%s"', method, HTTPS_PORT, path, H, body), function(err, stdout, stderr) {
    cb(err, JSON.parse(stdout))
  })
}
global.httpTest = function(method, path, headers, body, cb) {return HTTP_TEST(method, path, headers, body, cb)}
global.httpsTest = function(method, path, headers, body, cb) {return CURL(method, path, headers, body, cb)}

global.harchiver = spawn('./harchiver', [HTTP_PORT+'', SERVICE_TOKEN, '-https', HTTPS_PORT])

// Because Node.JS is dumb
// This is a C++ call that's a blocking sleep to give HARchiver enough time to start.
// Because Node.JS is terrible at spawning background processes and doing actions on them once they're ready.
// Other solutions start a subshell that leaves a mess behind.
sleep.usleep(500000) // 500 ms is way more than enough
var files = fs.readdirSync('./test')
for (var f in files) {
  var stat = fs.statSync('./test/' + files[f])
  if (!stat.isDirectory()) {
    try {
      require('./' + files[f])
    } catch (e) {
      console.error(e.toString())
    }
  }
}

