struct llist_node {
	struct llist_node *next;
	struct data_before* data;
};

struct data_before {
	void* data;
};

struct data_after {
	struct llist_node node;
	void *data;
};
