#include <stdlib.h>
#include <time.h>

int* delegate(size_t size) {
	// found by default to show different functions are found
	int* distraction = malloc(sizeof(int));
	free(distraction);

	return malloc(size);
}

int main(void) {
	srand(time(NULL));

	// this one is direct and gets found
	int* local = malloc(sizeof(int));
	// this one's indirect, so it doesn't
	int* delegated = delegate(sizeof(int));
	
	// this one gets found by setting max size to 64
	int* capped = malloc(sizeof(int) * (rand() % 16 + 1));

	// this one gets found by setting max size to 4 * 32768
	// (RAND_MAX in frama-c + 1), i.e. 131072
	int* randomly = malloc(sizeof(int) * (rand() + 1));

	int* fixed = NULL;
	if (rand() % 2) {
		// this one gets found by default
		fixed = malloc(sizeof(int));
	} else {
		// this one gets found by setting max size to 4*10000 i.e. 40000
		fixed = malloc(sizeof(int) * 10000);
	}

	// gets found by default
	int* varied = malloc(sizeof(int));
	if (rand() % 2) {
		// gets found if max size set to 4 * 17 i.e. 68
		varied = malloc(sizeof(int) * 17);
	}

	free(local);
	free(delegated);
	free(randomly), free(capped);
	free(fixed);
	free(varied);
	return 0;
}
