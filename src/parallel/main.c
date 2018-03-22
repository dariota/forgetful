#include <stdio.h>
#include <time.h>
#include <pthread.h>
#include <sys/time.h>

#include "benchmark.h"

#define TIME_SEC 2
#define THREAD_COUNT 4
#define BENCH_COUNT 10

union function_option {
	void (*bench_func)(size_t,bench_item*);
	void (*extra_bench_func)(size_t,bench_item*,bench_item*);
};

struct bench_info {
	volatile int *done;
	volatile int *start;
	size_t len;
	bench_item *items;
	bench_item *extra_items;
	union function_option func;
};

void *worker(void *arg) {
	struct bench_info *info = arg;
	while (!(*info->start));
	int complete_count = 0;

	// explicit hoisting to be sure the common expression's handled
	size_t len = info->len;
	bench_item *items = info->items;
	bench_item *extra_items = info->extra_items;

	// explicit duplication to avoid branching in core loop
	if (info->extra_items == NULL) {
		for (; !(*info->done); complete_count++) {
			(*info->func.bench_func)(len, items);
		}
	} else {
		for (; !(*info->done); complete_count++) {
			(*info->func.extra_bench_func)(len, items, extra_items);
		}
	}

	// explicit conversions to avoid warnings
	return (void*) (long int) complete_count;
}

void show_time(const char * description, size_t items, struct timeval start, struct timeval end, long int actions) {
	int secs = end.tv_sec - start.tv_sec;
	int usecs = end.tv_usec - start.tv_usec;
	if (usecs < 0) {
		secs -= 1;
		usecs += 1000000;
	}

	printf("%s,%u,%f,%ld\n", description, items, (secs + (usecs / 1000000.0)), actions);
}

void run_benchmark(const char *description, size_t *lens, bench_item **items, bench_item *extra_items[THREAD_COUNT][BENCH_COUNT], union function_option bench_func) {
	for (int i = 0; i < BENCH_COUNT; i++) {
		volatile int done = 0;
		volatile int start = 0;
		pthread_t threads[THREAD_COUNT];
		struct bench_info info[THREAD_COUNT];
		for (int j = 0; j < THREAD_COUNT; j++) {
			info[j].done = &done;
			info[j].start = &start;
			info[j].len = lens[i];
			info[j].items = items[i];
			info[j].extra_items = extra_items[j][i];
			info[j].func = bench_func;
			pthread_create(&threads[j], NULL, worker, &info[j]);
		}

		start = 1;
		struct timeval start_t;
		gettimeofday(&start_t, NULL);
		struct timeval target_t;
		target_t.tv_sec = start_t.tv_sec + TIME_SEC;
		struct timeval current_t;
		do {
			gettimeofday(&current_t, NULL);
		} while (current_t.tv_sec < target_t.tv_sec || (current_t.tv_sec == target_t.tv_sec && current_t.tv_usec < start_t.tv_usec));
		done = 1;
		gettimeofday(&current_t, NULL);

		long int total = 0;
		for (int j = 0; j < THREAD_COUNT; j++) {
			void *retval = 0;
			pthread_join(threads[j], &retval);
			total += (long int) retval;
		}
		show_time(description, lens[i], start_t, current_t, total);
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

	size_t lens[BENCH_COUNT] = {1, 2, 4, 8, 16, 32, 64, 128, 256, 512};
	bench_item *items[BENCH_COUNT];
	bench_item *extra_items[THREAD_COUNT][BENCH_COUNT];
	for (int i = 0; i < THREAD_COUNT; i++) {
		extra_items[i][0] = malloc(sizeof(bench_item) * lens[BENCH_COUNT - 1]);
	}
	bench_item *null_items[THREAD_COUNT][BENCH_COUNT];
	for (int i = 0; i < BENCH_COUNT; i++) {
		items[i] = malloc(sizeof(bench_item) * lens[i]);
		for (int j = 0; j < THREAD_COUNT; j++) {
			null_items[j][i] = NULL;
			extra_items[j][i] = extra_items[j][0];
		}

		// avoid false sharing
		int acceptable_diff = 0;
		do {
			long int min_diff = abs(extra_items[0][i] - items[i]);
			for (int j = 1; j < THREAD_COUNT; j++) {
				long int diff = abs(extra_items[j][i] - items[i]);
				if (diff < min_diff) min_diff = diff;
			}
			if (min_diff >= 100000) acceptable_diff = 1;
			items[i] = malloc(sizeof(bench_item) * lens[i]);
		} while (!acceptable_diff);

		for (size_t j = 0; j < lens[i]; j++) {
			items[i][j].id = j;
			items[i][j].value = rand();
		}
	}

	union function_option func;
	func.extra_bench_func = &benchmark_with_external;
	run_benchmark("EXTERNAL", lens, items, extra_items, func);
	func.bench_func = benchmark_with_malloc;
	run_benchmark("MALLOC", lens, items, null_items, func);
	func.bench_func = benchmark_with_dynamic;
	run_benchmark("DYNAMIC", lens, items, null_items, func);
	func.bench_func = benchmark_with_stack;
	run_benchmark("STACK", lens, items, null_items, func);
}
