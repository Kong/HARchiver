var fs = require('fs')
var zmq = require('zmq')
var sleep = require('sleep')
var request = require('superagent')
var spawn = require('child_process').spawn
var exec = require('child_process').exec
var util = require('util')
var validate = require('alf-validator')
var HTTP_PORT = 15555
var HTTPS_PORT = 15556
var ZMQ_PORT = 15557
global.SERVICE_TOKEN = 'defaultServiceToken'
SUPERAGENT = function(method, path, headers, body, cb) {
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

var sock = zmq.socket('pull')
sock.bindSync(util.format('tcp://*:%s', ZMQ_PORT))
global.httpTest = function(protocol, method, path, headers, body, cb) {
  var _err1, _alf = null, _err2 = null, _parsed = null, _result = null
  sock.removeAllListeners('message')
  sock.on('message', function(data) {
    var str = data.toString('utf8')
    _alf = JSON.parse(str.slice(str.indexOf(' ')))
    validate.single(_alf, {version:'1.0.0'}, function(err, valid) {
      _err1 = err != null ? new Error(JSON.stringify(err.errors)) : null
      if (_parsed != null) cb(_err2 != null ? _err2 : _err1, _parsed, _alf, _result)
    })
  })
  return (protocol.toLowerCase() === 'http' ? SUPERAGENT : CURL)(method, path, headers, body, function(err, parsed, result) {
    _err2 = err
    _parsed = parsed
    _result = result
    if (_alf != null) cb(_err2 != null ? _err2 : _err1, _parsed, _alf, _result)
  })
}

global.getEntry = function(alf) {return alf.har.log.entries[0]}
global.parseHeaders = function(headers) {
  var result = {}
  for (var h in headers) {
    result[headers[h].name] = headers[h].value
  }
  return result
}
global.lowerCaseObj = function(obj) {
  for (var k in obj) {
    var value = obj[k]
    var lower = k.toLowerCase()
    delete obj[k]
    obj[lower] = value
  }
  return obj
}

global.harchiver = spawn('./harchiver', [HTTP_PORT+'', SERVICE_TOKEN, '-https', HTTPS_PORT, '-host', '127.0.0.1', '-port', ZMQ_PORT])

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

