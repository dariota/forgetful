#ifndef BENCHMARK_H
#define BENCHMARK_H

#include <stdlib.h>

#define STACK_ALLOC_BYTE_LIMIT 512
#define MAX_COUNT(X) (STACK_ALLOC_BYTE_LIMIT / sizeof(X))

typedef struct benchmark_item {
	int id;
	int value;
} bench_item;

void benchmark_with_malloc(size_t, bench_item*);

void benchmark_with_stack(size_t, bench_item*);

void benchmark_with_dynamic(size_t, bench_item*);

void benchmark_with_external(size_t, bench_item*, bench_item*);

#endif
