#include <zmq.h>
#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <caml/alloc.h>
#include <caml/threads.h>

void* get_context() {
	return zmq_ctx_new();
}

void* get_sock(void* context, char* addr) {
	void *requester = zmq_socket (context, ZMQ_PUSH);
	zmq_connect (requester, addr);
	return requester;
}

void send_msg(void* requester, char** str, int len) {
	// caml_release_runtime_system();

	assert(zmq_send(requester, *str, len, 0) == len);

	// caml_acquire_runtime_system();
}
