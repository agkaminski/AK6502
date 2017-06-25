#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bus.h"
#include "error.h"

typedef struct bustree {
	struct bustree *right;
	struct bustree *left;
	busentry_t *entry;
} bustree_t;

static bustree_t bustree_root = { NULL, NULL, NULL };

static void bus_treeDump(bustree_t *tree)
{
	//TODO
}

static int bus_treeAdd(bustree_t *root, busentry_t *entry)
{
	if (entry->begin > entry->end)
		FATAL("Invalid entry (b: 0x%04x > e: 0x%04x)", entry->begin, entry->end);

	if (root->entry == NULL) {
		root->entry = entry;
		DEBUG("Inserting entry b: 0x%04x > e: 0x%04x at root", entry->begin, entry->end);
		return 0;
	}

	if (root->left != NULL) {
		if (root->left->entry->begin > entry->end)
			return bus_treeAdd(root->left, entry);
	}

	if (root->right != NULL) {
		if (root->right->entry->end < entry->begin)
			return bus_treeAdd(root->right, entry);
	}

	if (root->left == NULL && root->entry->begin > entry->end) {
		if ((root->left = malloc(sizeof(bustree_t))) == NULL)
			FATAL("Out of memory!");
		
		root->left->left = NULL;
		root->left->right = NULL;
		root->left->entry = entry;

		DEBUG("Inserting entry b: 0x%04x > e: 0x%04x at new left node", entry->begin, entry->end);
		
		return 0;
	}

	if (root->right == NULL && root->entry->end < entry->begin) {
		if ((root->right = malloc(sizeof(bustree_t))) == NULL)
			FATAL("Out of memory!");

		root->right->left = NULL;
		root->right->right = NULL;
		root->right->entry = entry;

		DEBUG("Inserting entry b: 0x%04x > e: 0x%04x at new right node", entry->begin, entry->end);
		
		return 0;
	}

	bus_treeDump(&bustree_root);
	FATAL("Could not insert entry b: 0x%04x e: 0x%04x", entry->begin, entry->end);

	return -1;
}

static void bus_treeCleanup(bustree_t *root)
{
	if (root->left != NULL)
		bus_treeCleanup(root->left);
	if (root->right != NULL)
		bus_treeCleanup(root->right);

	free(root->entry);

	if (root != &bustree_root)
		free(root);
}

static bustree_t *bus_treeFind(bustree_t *root, u16 addr)
{
	if (root == NULL)
		return NULL;

	if (root->entry->begin >= addr && root->entry->end <= addr)
		return root;

	if (root->entry->end > addr)
		return bus_treeFind(root->left, addr);
	else
		return bus_treeFind(root->right, addr);
}

void bus_write(u16 addr, u8 data)
{
	bustree_t *node;

	node = bus_treeFind(&bustree_root, addr);

	if (node == NULL)
		FATAL("Invalid bus access (address 0x%04x)", addr);

	if (node->entry == NULL)
		FATAL("Corrupted tree - entry == NULL");

	node->entry->write(addr - node->entry->begin, data);
}

u8 bus_read(u16 addr)
{
	bustree_t *node;

	node = bus_treeFind(&bustree_root, addr);

	if (node == NULL)
		FATAL("Invalid bus access (address 0x%04x)", addr);

	if (node->entry == NULL)
		FATAL("Corrupted tree - entry == NULL");

	return node->entry->read(addr - node->entry->begin);
}

void bus_register(busentry_t entry)
{
	busentry_t *newEntry;

	if ((newEntry = malloc(sizeof(busentry_t))) == NULL)
		FATAL("Out of memory!");

	memcpy(newEntry, &entry, sizeof(*newEntry));

	bus_treeAdd(&bustree_root, newEntry);
}

void bus_cleanup(void)
{
	bus_treeCleanup(&bustree_root);
}
