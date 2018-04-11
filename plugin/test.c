#include <stdio.h>
#include <stdlib.h>

int f(int *a) {
	*a = 0;
	(*a)++;
	return *a;
}

int main(int argc, char* argv) {
	int sizeDef = rand();
	int *blah = malloc(sizeof(int));
	printf("%u\n", &sizeDef + sizeof(int));
	int *blah2 = malloc(sizeof(int) * sizeDef);
	int *blah4 = malloc(sizeof(int) + &sizeDef);
	int **blah3 = malloc(sizeof(int*) * 10 + sizeof(malloc(1)));
	int *varSize = malloc(sizeof(int) * (rand() % 12 + 1));
	malloc(0);
	if (!blah || !blah2 || !blah3)
		return 1;
	if (malloc(1)) {
		puts("hi");
	} else {
		puts("bye");
	}
	blah3[1] = malloc(sizeof(int));
	int *copy = blah;

	if (rand() < 0)
		printf("Hello world, %d!\n", 4);
	*blah = 1;
	{
		blah = malloc(sizeof(int));
		if (!blah) return 2;
		*blah = 2;
	}

	int i = 0;
	while (!i) {
		printf("Hello again.\n");
		i++;
	}

	malloc(sizeof(int));
	printf("%p\n", malloc(sizeof(int))+1);
	free(copy), free(blah2), free(malloc(sizeof(int))), free(varSize);

	int arg = f(malloc(sizeof(int)));
	if (!arg) return 1;
	malloc(sizeof(int));

	return 3 * i;
}
