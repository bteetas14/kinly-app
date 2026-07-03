package repositories

import (
	"strings"
	"testing"

	"kinly/backend/internal/dto"
)

func TestProductWhereCombinesCategoryAndBrand(t *testing.T) {
	where, args := productWhere(dto.ProductFilters{
		Category: "body-care",
		Brand:    "Everyday Beauty",
	})

	if !strings.Contains(where, "b.name ILIKE $1") {
		t.Fatalf("expected brand filter in query, got %q", where)
	}
	if !strings.Contains(where, "c.slug = $2") {
		t.Fatalf("expected category filter in query, got %q", where)
	}
	if len(args) != 2 || args[0] != "Everyday Beauty" || args[1] != "body-care" {
		t.Fatalf("unexpected filter arguments: %#v", args)
	}
}
