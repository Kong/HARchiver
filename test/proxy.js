var request = require('superagent')
var assert = require('assert')
var util = require('util')

describe('Proxy', function() {
	describe('Protocols', function() {
		it('HTTP -> HTTP', function(done) {
			httpTest('GET', 'get', [['Host', 'httpbin.org']], '', function(err, parsed, result) {
				assert(err == null)
				assert(parsed.url === 'http://httpbin.org/get')
				done(err)
			})
		})

		it('HTTP -> HTTPS', function(done) {
			httpTest('GET', 'get', [['Host', 'httpbin.org'], ['Mashape-Upstream-Protocol', 'https']], '', function(err, parsed, result) {
				assert(err == null)
				assert(parsed.url === 'https://httpbin.org/get')
				done(err)
			})
		})

		it('HTTPS -> HTTP', function(done) {
			httpsTest('GET', 'get', [['Host', 'httpbin.org'], ['Mashape-Upstream-Protocol', 'http']], '', function(err, parsed) {
				assert(err == null)
				assert(parsed.url === 'http://httpbin.org/get')
				done(err)
			})
		})

		it('HTTPS -> HTTPS', function(done) {
			httpsTest('GET', 'get', [['Host', 'httpbin.org']], '', function(err, parsed) {
				assert(err == null)
				assert(parsed.url === 'https://httpbin.org/get')
				done(err)
			})
		})
	})
})
