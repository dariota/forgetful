int func(size_t alloc_size) {
	void* alloced = malloc(alloc_size);
	int result = // do things with alloced
	free(alloced);
	return result;
}
