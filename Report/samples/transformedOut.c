void main(void) {
	void* alloced = malloc(1) + 1;
	free(alloced - 1);
}
