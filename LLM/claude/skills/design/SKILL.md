---
name: design
description: Design a new module, package, service boundary or structural change with hexagonal architecture (ports and adapters) and deep modules. Use when planning new modules or changes to layering and dependencies, not for small edits inside existing code.
argument-hint: "<feature or module to design>"
---

Design $ARGUMENTS and add the result to the plan as a **Design** section. Don't write code until the plan is approved.

## 1. Start from the existing codebase

- Find how the codebase already structures similar features and follow it. If it differs from the defaults below, the codebase wins; propose a change only in the plan, with the cost.
- Check proportionality first. A script, glue code, a one-off ETL step or simple CRUD over one table doesn't need ports or layers. Say so and design it flat.

## 2. Hexagonal defaults

- **Domain** (pure): entities, value objects, domain services, domain errors. No framework, DB, HTTP, filesystem or clock access. Everything here is testable with plain unit tests.
- **Application** (use cases): one entry point per use case, orchestrating domain objects and ports. Business rules live in the domain, not here and not in adapters.
- **Ports**: `Protocol`s / interfaces owned by the core (domain or application layer — follow the project). Name them for the need, not the technology (`OrderRepository`, `Clock`, `PaymentGateway`, not `PostgresClient` or `StripeClient`). Keep them small and intention-revealing, with domain types in and out.
- **Driving adapters** (HTTP handlers, CLI, consumers, schedulers): parse and validate input, call a use case, map the result to the transport. No business logic.
- **Driven adapters** (DB, external APIs, queues, files): implement a port and map external types to domain types and back at the boundary. Nothing external leaks inward.
- **Composition root**: one place (app factory, `main()`, framework DI setup) wires concrete adapters to ports. No globals or singletons reached from inside the core.

Example Python layout (adapt names to the project):

```
src/<package>/
  domain/            # entities, value objects, domain errors — pure
  application/       # use cases + the ports they need (Protocols)
  adapters/
    inbound/         # http, cli, consumers -> call use cases
    outbound/        # db, external APIs, queues -> implement ports
  bootstrap.py       # composition root
```

## 3. Deep modules

- Each module should hide a real decision (a format, a protocol, a calculation) behind an interface much simpler than its implementation.
- Avoid shallow pass-through layers, one-method classes that only forward calls, and splitting cohesive sequential logic across many tiny functions.
- Prefer few general-purpose operations over many special-case ones, without adding options nobody needs.

## 4. Test plan per layer

- Domain: unit tests, no fakes.
- Use cases: in-memory fakes of each port.
- Driven adapters: integration tests against the real dependency where practical (contract tests if several adapters share a port).
- Acceptance: one Given / When / Then scenario per ticket criterion, through a use case or the API.

## 5. Output in the plan

- Module map: each new or changed module, its layer and its single responsibility.
- Ports with their signatures and the domain types crossing them.
- Data flow for the main use case, inbound to outbound.
- What is tested at which level.
- Trade-offs: the simpler alternative you rejected and why. If the simpler option is good enough, recommend it instead.
