#include <stdlib.h>
#include <time.h>

int* delegate(size_t size) {
	// this one gets found, intended to prevent function inlining
	int* distraction = malloc(size * 2);
	free(distraction);

	return malloc(size);
}

int main(void) {
	srand(time(NULL));

	// these both get found by default
	int* local = malloc(sizeof(int));
	int* delegated = delegate(sizeof(int));
	
	// this one gets found by setting max size to 64
	int* capped = malloc(sizeof(int) * (rand() % 16 + 1));

	// this one gets found by setting max size to 4 * 32768
	// (RAND_MAX in frama-c + 1)
	int* randomly = malloc(sizeof(int) * (rand() + 1));

	// and this one only gets found by setting max size to the larger of the
	// branches, i.e. 40000
	int* fixed = NULL;
	if (rand() % 2) {
		fixed = malloc(sizeof(int));
	} else {
		fixed = malloc(sizeof(int) * 10000);
	}

	// similar to the above, it gets found if set to the larger of the two
	// options, so 68
	int* varied = malloc(sizeof(int));
	if (rand() % 2) {
		varied = malloc(sizeof(int) * 17);
	}

	free(local);
	free(delegated);
	free(randomly), free(capped);
	free(fixed);
	free(varied);
	return 0;
}
