#include <stdio.h>
#include <stdlib.h>

int f(int *a) {
	(*a)++;
	return *a;
}

int main(int argc, char* argv) {
	int *blah = malloc(sizeof(int));
	if (!blah)
		return 1;
	int *copy = blah;

	if (rand() < 0)
		printf("Hello world, %d!\n", 4);
	*blah = 1;

	int i = 0;
	while (!i) {
		printf("Fuck y'all.\n");
		i++;
	}

	printf("%d\n", *blah);
	free(blah);

	int *arg = malloc(sizeof(int));
	if (!arg) return 1;
	malloc(sizeof(int));
	int adjust = f(arg);

	return 3 * i;
}
