#include <stdarg.h>
#include <stdio.h>
#include <libinput.h>
#include <caml/mlvalues.h>
#include <caml/unixsupport.h>
#include "stubs.h"

value caml_libinput_code_of_unix_error(value v_error) { return Val_int(caml_unix_code_of_unix_error(v_error)); }
value caml_libinput_unix_error_of_code(value v_errno) { return caml_unix_error_of_code(Int_val(v_errno)); }

static void c_handler(struct libinput *context, enum libinput_log_priority priority, const char *format, va_list args) {
	caml_libinput_log_handler_simple handler = libinput_get_user_data(context);
	va_list args_copy;

	va_copy(args_copy, args);

	int needed = vsnprintf(NULL, 0, format, args);
	va_end(args);

	size_t size = needed + 1;
	char *buf = malloc(size);
	if (buf) {
		vsnprintf(buf, size, format, args_copy);
		va_end(args_copy);
		handler(priority, buf);
		free(buf);
	} else {
		va_end(args_copy);
		handler(LIBINPUT_LOG_PRIORITY_ERROR, "Log handler out of memory");
	}
}

void caml_libinput_log_set_handler_simple(struct libinput *context, caml_libinput_log_handler_simple handler) {
	libinput_set_user_data(context, handler);
	libinput_log_set_handler(context, c_handler);
}
