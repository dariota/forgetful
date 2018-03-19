#include <stdio.h>
#include <time.h>

#include "benchmark.h"

void show_time(clock_t start, const char * description, size_t items) {
	clock_t end = clock();
	double total = ((double)(end - start)) / CLOCKS_PER_SEC;

	printf("%s,%u,%fs\n", description, items, total);
}

void run_benchmark(const char *description, long int runs, size_t *lens, bench_item **items, void (*bench_func)(size_t, bench_item*)) {
	for (int i = 0; i < 8; i++) {
		size_t len = lens[i];
		clock_t start = clock();
		for (long int j = 0; j < runs; j++) {
			(*bench_func)(len, items[i]);
		}
		show_time(start, description, len);
	}
}

int main(int argc, char *argv[]) {
	long int runs;
	if (argc == 1) {
		runs = 10000L;
	} else if (argc == 2) {
		char *endptr = NULL;
		runs = strtol(argv[1], &endptr, 10);
		
		if (endptr == NULL) {
			fprintf(stderr, "Input '%s' is not a valid number\n", argv[1]);
			return 2;
		}
	} else {
		printf("Usage: %s [runs]\n"
		       "\tRuns the benchmark, calling each function 'runs' times, or 10000 times if omitted.\n",
			   argv[0]);
		return 1;
	}

	if (runs < 1) {
		fprintf(stderr, "Invalid number of runs: %d\n", runs);
		return 2;
	}

	srand(time(NULL));

	size_t lens[8] = {1, 8, 32, 64, 128, 256, 512, 8196};
	bench_item *items[8];
	for (int i = 0; i < 8; i++) {
		items[i] = malloc(sizeof(bench_item) * lens[i]);
		for (size_t j = 0; j < lens[i]; j++) {
			items[i][j].id = j;
			items[i][j].value = rand();
		}
	}

	for (int i = 0; i < 8; i++) {
		size_t len = lens[i];
		bench_item *target = malloc(sizeof(bench_item) * lens[i]);
		clock_t start = clock();
		for (long int j = 0; j < runs; j++) {
			benchmark_with_external(len, items[i], target);
		}
		show_time(start, "EXTERNAL", len);
		free(target);
	}

	run_benchmark("MALLOC", runs, lens, items, &benchmark_with_malloc);
	run_benchmark("DYNAMIC", runs, lens, items, &benchmark_with_dynamic);
	run_benchmark("STACK", runs, lens, items, &benchmark_with_stack);
}
