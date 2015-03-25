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
	void *sock = zmq_socket (context, ZMQ_PUSH);
	zmq_connect (sock, addr);
	return sock;
}

char* say_hi() {
	return "Hi!";
}

// void to array to string
int send_msg(void* sock, char*** strings , int nb_strings, int* lengths) {
	caml_release_runtime_system();
	// char*** arr = (char ***) ptr;
	// char* str = *(ptr[1]);


	// assert(1 == 0);



	int i;
	for (i=0; i<nb_strings; i++) {




		assert(zmq_send(sock, *(strings[i]), lengths[i], 0) == lengths[i]);
	}

	caml_acquire_runtime_system();
	return i;
}
