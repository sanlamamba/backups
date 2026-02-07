---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python

- Run everything through the project's manager: `uv run pytest`, `uv run ruff check --fix <files>`, `uv run mypy` (or whatever the lockfile and `pyproject.toml` indicate). Add dependencies with the manager (`uv add`), never `pip install` into the environment.
- Type hints on every new or changed signature. Ports are `typing.Protocol`s; value objects are frozen dataclasses or the project's model library; use `Enum` or `Literal` instead of magic strings.
- Datetimes are timezone-aware. Inject a clock rather than calling `datetime.now()` in logic.
- Define domain-specific exceptions. No bare `except:`; `except Exception` only at the outermost boundary; re-raise with `raise ... from err`.
- No side effects at import time and no module-level mutable state.
- Log with `logging.getLogger(__name__)`, never `print` in library code. No secrets or full payloads in logs.
- pandas: use the project's wrappers or extensions when present; prefer vectorized operations over row-wise `apply`; avoid chained assignment.
- Mocks: `create_autospec(Thing, spec_set=True)`, never a bare `Mock()` or `MagicMock()`.
