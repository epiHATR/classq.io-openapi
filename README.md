# ClassQ.io OpenAPI

OpenAPI 3.1 contract for the ClassQ.io HTTP API. The application code lives in the sibling repo [`classqIO`](../classqIO). This repo is the API documentation.

`openapi.yaml` matches app version **1.1.9** (`classqIO/backend/VERSION`).

## What is documented

- Every route registered in `classqIO/backend/cmd/server/main.go`
- Request bodies taken from the Go structs those handlers decode
- Auth (`Authorization: Bearer`), permission gates, and the common `{ "error": "..." }` error body
- The callsign pack as it is reached through `/api/plugins/callsign/...`

Large domain responses use the `JsonObject` schema. Tighten that schema when you change the handler.

Learner exam state does **not** include `is_correct` on answer options. During an attempt, correctness is only returned by `POST /api/me/sessions/{sessionID}/answers/reveal`.

## Preview and lint

```bash
npm install
npm run lint
npm run preview
```

Preview serves the docs at <http://127.0.0.1:8089>. The preview script uses Redocly CLI 1, because CLI 2 removed `preview-docs`. Lint still uses the CLI 2 installed in this project.

## When the API changes

Update `openapi.yaml` in the same change as the ClassQ feature:

1. Add, edit, or remove the path and method.
2. Set `operationId`, tag, parameters, and request body.
3. Set `security: []` for public routes. Otherwise the document-level bearer scheme applies.
4. Set `x-classq-permission` when the route needs `content.manage`, `application.settings`, or `setup_admin`.
5. Bump `info.version` when `classqIO/backend/VERSION` changes.
6. Run `npm run lint`.

ClassQ agent rules in `classqIO/.cursor/rules/openapi-docs.mdc` require this update whenever a feature adds or changes an HTTP endpoint.
