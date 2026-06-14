package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

type Pagination struct {
	Page     int
	PageSize int
	Offset   int
}

func ReadPagination(c *gin.Context) Pagination {
	page := readInt(c, "page", 1)
	pageSize := readInt(c, "page_size", 20)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	return Pagination{Page: page, PageSize: pageSize, Offset: (page - 1) * pageSize}
}

func readInt(c *gin.Context, key string, fallback int) int {
	raw := c.Query(key)
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return value
}
