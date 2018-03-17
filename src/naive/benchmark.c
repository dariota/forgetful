#include "benchmark.h"

int compare_item(const void *i1, const void *i2) {
	if (i1 == i2) return 0;

	const bench_item *item1 = i1;
	const bench_item *item2 = i2;

	if (item2 == NULL) return 1;
	if (item1 == NULL) return -1;

	if (item1->value > item2->value) return 1;
	if (item1->value < item2->value) return -1;
	return 0;
}

void perform_busy_work(size_t len, bench_item* items, bench_item *target) {
	for (size_t i = 0; i < len; i++) {
		target[i] = items[i];
	}

	qsort(target, len, sizeof(bench_item), compare_item);
}

void benchmark_with_malloc(size_t len, bench_item* items) {
	bench_item* target = malloc(sizeof(bench_item) * len);
	perform_busy_work(len, items, target);
	free(target);
}

void benchmark_with_stack(size_t len, bench_item* items) {
	bench_item* target = alloca(sizeof(bench_item) * len);
	perform_busy_work(len, items, target);
}

void benchmark_with_dynamic(size_t len, bench_item* items) {
	bench_item* target;
	if (len < MAX_COUNT(bench_item)) {
		bench_item target_target[MAX_COUNT(bench_item)];
		target = &target_target[MAX_COUNT(bench_item) - len];
	} else {
		target = malloc(sizeof(bench_item) * len);
	}

	perform_busy_work(len, items, target);

	if (len >= MAX_COUNT(bench_item)) {
		free(target);
	}
}

void benchmark_with_external(size_t len, bench_item* items, bench_item* target) {
	perform_busy_work(len, items, target);
}
