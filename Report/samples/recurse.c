#include <stdlib.h>

void* recurse_and_free(int recurse) {
	if (recurse) {
		free(recurse_and_free(recurse - 1));
		return malloc(1);
	} else {
		return malloc(1);
	}
}

void main() {
	free(recurse_and_free(2));
}
