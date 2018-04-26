void* xmalloc(size_t size) {
	void* block = malloc(size);
	if (!block) exit(1);
	return block;
}

void main(void) {
	void* unreported = xmalloc(1);
	free(unreported);
}
