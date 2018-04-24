#include <stdlib.h>
#include <time.h>

int* delegate(size_t size) {
	// reported, as all functions are inspected
	int* distraction = malloc(sizeof(int));
	free(distraction);

	return malloc(size);
}

int main(void) {
	srand(time(NULL));

	// this one is directly allocated and is reported
	int* local = malloc(sizeof(int));
	// this one's indirectly allocated, so it isn't reported
	int* delegated = delegate(sizeof(int));

	// this one is reported by setting max size to 64
	int* capped = malloc(sizeof(int) * (rand() % 16 + 1));

	// this one is reported by setting max size to 4 * 32768
	// (RAND_MAX in frama-c + 1), i.e. 131072
	int* randomly = malloc(sizeof(int) * (rand() + 1));

	int* fixed = NULL;
	if (rand() % 2) {
		// this one is reported by default
		fixed = malloc(sizeof(int));
	} else {
		// this one is reported if the max size is set to 4 * 10000, i.e. 40000
		fixed = malloc(sizeof(int) * 10000);
	}

	// reported by default
	int* varied = malloc(sizeof(int));
	if (rand() % 2) {
		// reported if max size is set to 4 * 17 i.e. 68
		varied = malloc(sizeof(int) * 17);
	}

	free(local);
	free(delegated);
	free(randomly), free(capped);
	free(fixed);
	free(varied);
	return 0;
}
