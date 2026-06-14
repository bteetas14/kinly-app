package httpx

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
)

var (
	ErrNotFound     = errors.New("not found")
	ErrUnauthorized = errors.New("unauthorized")
	ErrForbidden    = errors.New("forbidden")
	ErrConflict     = errors.New("conflict")
	ErrInvalid      = errors.New("invalid request")
)

type ErrorBody struct {
	Error APIError `json:"error"`
}

type APIError struct {
	Code    string            `json:"code"`
	Message string            `json:"message"`
	Fields  map[string]string `json:"fields,omitempty"`
}

type Page[T any] struct {
	Data     []T   `json:"data"`
	Page     int   `json:"page"`
	PageSize int   `json:"page_size"`
	Total    int64 `json:"total"`
}

func OK(c *gin.Context, data any) {
	c.JSON(http.StatusOK, data)
}

func Created(c *gin.Context, data any) {
	c.JSON(http.StatusCreated, data)
}

func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

func Fail(c *gin.Context, err error) {
	status := http.StatusInternalServerError
	code := "internal_error"
	message := "Something went wrong."

	switch {
	case errors.Is(err, ErrInvalid):
		status, code, message = http.StatusBadRequest, "invalid_request", err.Error()
	case errors.Is(err, ErrUnauthorized):
		status, code, message = http.StatusUnauthorized, "unauthorized", "Authentication is required."
	case errors.Is(err, ErrForbidden):
		status, code, message = http.StatusForbidden, "forbidden", "You do not have permission to perform this action."
	case errors.Is(err, ErrNotFound):
		status, code, message = http.StatusNotFound, "not_found", "The requested resource was not found."
	case errors.Is(err, ErrConflict):
		status, code, message = http.StatusConflict, "conflict", err.Error()
	default:
		message = err.Error()
	}

	c.AbortWithStatusJSON(status, ErrorBody{Error: APIError{Code: code, Message: message}})
}

func Validation(c *gin.Context, fields map[string]string) {
	c.AbortWithStatusJSON(http.StatusBadRequest, ErrorBody{
		Error: APIError{Code: "validation_error", Message: "Validation failed.", Fields: fields},
	})
}
