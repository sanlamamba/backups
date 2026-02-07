---
paths:
  - "**/test_*.py"
  - "**/*_test.py"
  - "**/conftest.py"
  - "**/tests/**"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/*.spec.ts"
  - "**/*.spec.tsx"
  - "**/*.feature"
---

# Writing tests

Follow the project's existing test style first; these are the defaults.

- Name tests as behavior sentences so a file's test names read as the unit's spec: `test_rejects_weights_that_sum_above_one`, `test_<outcome>_when_<condition>`; TS `it("rejects weights that sum above one")`. A failing name plus its message should say what broke without opening the test.
- Structure each test as Given / When / Then (Arrange / Act / Assert), separated by blank lines. One behavior and one action per test.
- Assert on outcomes visible through the public interface: return values, state read back through the public API, emitted events, calls made to ports. Not private methods, internal call order or log text, unless that is the contract.
- Example tables go in parametrization, not loops or copy-pasted tests.
- Build test data with small factories or builders with sensible defaults; set only the fields the test is about.
- Tests are deterministic and isolated: no sleeps, real clocks, network or order dependence.

## Levels (follow the project's split if it has one)

- Domain: plain unit tests on pure code, no fakes needed.
- Application / use cases: in-memory fakes of the ports.
- Adapters: integration tests against real dependencies where practical (local DB, testcontainers). Mock only third-party network services.
- End-to-end: few, for critical flows only.

## Fakes and mocks

- A fake is a small in-memory implementation of the port, passed as a parameter or fixture. Keep shared fakes in one place; don't redefine them per test.
- Mock only network, time and external services, always type-checked: `create_autospec(Thing, spec_set=True)`, `createMock<T>()`. Prefer injecting a fixed clock over patching time.

## BDD

- Write acceptance criteria as Given / When / Then scenarios and turn each into one acceptance test (outer loop of the `tdd` skill).
- Use Gherkin with `pytest-bdd` or `behave` only where the project already does; otherwise express scenarios as plain tests named and structured Given / When / Then.
