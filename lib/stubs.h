#include <caml/mlvalues.h>

typedef void (*caml_libinput_log_handler_simple)(
		enum libinput_log_priority priority,
		const char *message);

void caml_libinput_log_set_handler_simple(
		struct libinput *context,
		caml_libinput_log_handler_simple handler);
