#include <stdio.h>
#include <stdlib.h>

int f(int *a) {
	*a = 0;
	(*a)++;
	return *a;
}

int main(int argc, char* argv) {
	int *blah = malloc(sizeof(int));
	int *blah2 = malloc(sizeof(int));
	if (!blah || !blah2)
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

	malloc(sizeof(int));
	printf("%p\n", malloc(sizeof(int))+1);
	free(copy), free(blah2), free(malloc(sizeof(int)));

	int arg = f(malloc(sizeof(int)));
	if (!arg) return 1;
	malloc(sizeof(int));

	return 3 * i;
}
