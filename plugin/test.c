#include <stdio.h>
#include <stdlib.h>

int f(int *a) {
	(*a)++;
	return *a;
}

int main(int argc, char* argv) {
	if (rand() < 0)
		printf("Hello world, %d!\n", 4);

	int i = 0;
	while (!i) {
		printf("Fuck y'all.\n");
		i++;
	}

	return 3 * i;
}
