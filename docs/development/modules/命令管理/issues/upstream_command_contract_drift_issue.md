## Summary

`/core/commands/tree` and command-list related contract definitions are inconsistent between runtime router and generated Swagger.

- Runtime router (actual behavior): `POST`
- API annotations / generated Swagger (current docs): `GET`

This drift causes client generation and contract-driven gateways to fail.

## Evidence

### 1) Runtime router registers POST

File: `core/router/command.go`

```go
commandRouter.POST("/list", baseApi.ListCommand)
commandRouter.POST("/tree", baseApi.SearchCommandTree)
```

### 2) API annotations still mark GET

File: `core/app/api/v2/command.go`

```go
// @Router /core/commands/tree [get]
func (b *BaseApi) SearchCommandTree(c *gin.Context) { ... }

// @Router /core/commands/command [get]
func (b *BaseApi) ListCommand(c *gin.Context) { ... }
```

### 3) Generated Swagger exports GET + body

File: `core/cmd/server/docs/swagger.json`

- `"/core/commands/tree": { "get": ... }`
- `"/core/commands/command": { "get": ... }`
- Both include `in: "body"`, which is contradictory for strict GET contract validation.

## Impact

1. Contract-first clients generated from Swagger may use GET and fail against runtime POST-only routing.
2. API gateways or policy layers enforcing Swagger method can reject working runtime requests.
3. Downstream clients need temporary compatibility workarounds and extra regression tests.

## Expected fix

1. Align annotations with runtime router truth.
2. Clarify the list endpoint path contract (`/core/commands/list` vs `/core/commands/command`) and method.
3. Regenerate Swagger/docs artifacts after annotation fix.
4. Add a CI guard to detect router-vs-annotation method drift for command endpoints.

## Suggested acceptance

- Swagger methods for command tree/list endpoints match runtime router methods.
- Existing web/mobile clients can use one consistent contract without custom fallback logic.
