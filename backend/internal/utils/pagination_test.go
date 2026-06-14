package utils

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestReadPaginationDefaultsAndCapsPageSize(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(recorder)
	req := httptest.NewRequest(http.MethodGet, "/products?page=0&page_size=500", nil)
	ctx.Request = req

	page := ReadPagination(ctx)

	if page.Page != 1 {
		t.Fatalf("page = %d, want 1", page.Page)
	}
	if page.PageSize != 100 {
		t.Fatalf("page size = %d, want 100", page.PageSize)
	}
	if page.Offset != 0 {
		t.Fatalf("offset = %d, want 0", page.Offset)
	}
}
