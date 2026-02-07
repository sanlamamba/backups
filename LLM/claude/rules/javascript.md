---
paths:
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
---

# JavaScript

- Use the package manager the lockfile indicates (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock` → bun, `package-lock.json` → npm) and the project's own scripts for test, lint and build.
- Match the module system the package uses (`"type"` in `package.json` and the existing files). Never mix ESM and CommonJS within one package.
- If the project type-checks JS (`// @ts-check`, `checkJs`, JSDoc types), type new and changed code the same way. Ports are documented with JSDoc `@typedef` / `@callback` and passed in as parameters.
- No types at runtime, so parse and validate external data at the boundary, with the project's schema library if it has one.
- Async: every promise is awaited or returned; no floating promises; handle rejections at the boundary; don't mix callbacks and promises in one flow.
- Prefer built-ins (`fetch`, `structuredClone`, `crypto.randomUUID`, `Array.prototype.at`) over adding a dependency for the same thing.
- Mocks keep the real module's shape (`jest.createMockFromModule`, `vi.mock` with `importOriginal`), never an ad-hoc object standing in for a module.