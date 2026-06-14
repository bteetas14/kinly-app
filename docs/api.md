# Kinly MVP API

All JSON error responses use:

```json
{
  "error": {
    "code": "invalid_request",
    "message": "Readable message",
    "fields": {
      "field": "problem"
    }
  }
}
```

Paginated responses use:

```json
{
  "data": [],
  "page": 1,
  "page_size": 20,
  "total": 0
}
```

## Auth

- `POST /signup`
- `POST /login`
- `POST /logout`

## Products

- `GET /products`
- `GET /products/{id}`
- `GET /products/search?q=serum`

Supports `page`, `page_size`, `sort`, `brand`, `min_price`, `max_price`, `skin_type`, `sensitive_skin`, `cruelty_free`, `fragrance_free`, and `vegan`.

## Reviews

- `POST /reviews`
- `GET /products/{id}/reviews`
- `DELETE /reviews/{id}`
- `POST /reviews/{id}/helpful`
- `POST /reviews/{id}/comments`

## Community

- `POST /posts`
- `GET /posts`
- `GET /posts/{id}`
- `POST /posts/{id}/vote`
- `POST /posts/{id}/report`
- `POST /comments`
- `DELETE /comments/{id}`

## Notifications and Users

- `GET /notifications`
- `PATCH /notifications/{id}/read`
- `GET /users/{id}`
- `PATCH /users/profile`
