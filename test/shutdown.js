describe('Shutdown', function() {
	it('Should stop cleanly', function(done) {
		harchiver.kill()
		done()
	})
})
