---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

# TypeScript

- Use the package manager the lockfile indicates (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock` → bun, `package-lock.json` → npm) and the project's own scripts for test, lint and typecheck.
- No `any`, non-null `!`, or `as` casts (except `as const`). Narrow with type guards and parse external data at the boundary with the project's schema library.
- Ports are `interface`s owned by the core; adapters implement them.
- Prefer discriminated unions over boolean flags and bags of optional fields.
- Typed mocks only: `createMock<T>()` or the project's equivalent, never an untyped `jest.fn()` object cast to a type.
