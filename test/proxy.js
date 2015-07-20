var assert = require('assert')
var util = require('util')

describe('Proxy', function() {
  describe('Protocols', function() {
    it('HTTP -> HTTP', function(done) {
      httpTest('http', 'GET', 'get', [['Host', 'httpbin.org']], '', function(err, parsed, alf, result) {
        assert(err == null)
        assert(parsed.url === 'http://httpbin.org/get')
        done(err)
      })
    })

    it('HTTP -> HTTPS', function(done) {
      httpTest('http', 'GET', 'get', [['Host', 'httpbin.org'], ['Mashape-Upstream-Protocol', 'https']], '', function(err, parsed, alf, result) {
        assert(err == null)
        assert(parsed.url === 'https://httpbin.org/get')
        done(err)
      })
    })

    it('HTTPS -> HTTP', function(done) {
      httpTest('https', 'GET', 'get', [['Host', 'httpbin.org'], ['Mashape-Upstream-Protocol', 'http']], '', function(err, parsed, alf) {
        assert(err == null)
        assert(parsed.url === 'http://httpbin.org/get')
        done(err)
      })
    })

    it('HTTPS -> HTTPS', function(done) {
      httpTest('https', 'GET', 'get', [['Host', 'httpbin.org']], '', function(err, parsed, alf) {
        assert(err == null)
        assert(parsed.url === 'https://httpbin.org/get')
        done(err)
      })
    })
  })

  describe('Headers', function() {
    it('Should sanitize headers', function(done) {
      httpTest('http', 'GET', 'get?show_env=1', [['Host', 'httpbin.org']], '', function(err, parsed, alf, result){
        var alfHeaders = parseHeaders(getEntry(alf).request.headers)
        var httpHeaders = lowerCaseObj(parsed.headers)
        assert(alfHeaders['mashape-service-token'] == null)
        assert(httpHeaders['mashape-service-token'] == null)

        assert(alfHeaders['mashape-host-override'] == null)
        assert(httpHeaders['mashape-host-override'] == null)

        assert(alfHeaders['mashape-environment'] == null)
        assert(httpHeaders['mashape-environment'] == null)

        assert(alfHeaders['mashape-upstream-protocol'] == null)
        assert(httpHeaders['mashape-upstream-protocol'] == null)

        assert(alfHeaders['x-forwarded-proto'] == null)
        assert(httpHeaders['x-forwarded-proto'] == null)

        assert(alfHeaders['x-forwarded-for'] != null)
        assert(httpHeaders['x-forwarded-for'] != null)

        done()
      })
    })
  })
})
