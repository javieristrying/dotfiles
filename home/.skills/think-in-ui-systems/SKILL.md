---
name: think-in-ui-systems
description: Designs and implements domain UI as connected action systems in React applications using Next.js, Tailwind CSS, and Motion. Use when creating or refactoring product flows, domain components, design-system patterns, async actions, cross-component state, or interaction architecture instead of working on isolated components.
---

# Think in UI Systems

## Goal

Design the user outcome, domain rules, states, effects, and recovery before editing isolated components.

Use this order:

```text
Outcome -> actors -> objects -> rules -> states -> actions -> effects -> feedback -> recovery -> measurement
```

Read [REFERENCE.md](REFERENCE.md) for stack rules, [TEMPLATES.md](TEMPLATES.md) for artifacts, and [EXAMPLES.md](EXAMPLES.md) for a Next.js example.

## Start here

1. Read project instructions and inspect the real user flow before editing.
2. Find the feature route, domain types, mutations, components, styles, tests, and analytics.
3. Reproduce the current flow in the running app when fixing behavior.
4. Choose one domain action as the work unit, not one visual component.
5. State the outcome and the rules that must remain true.

## Build the system model

Create or update a short model using the project docs convention. If none exists, propose `docs/ui-systems/<feature>/`.

Capture:

- Actors, domain objects, relationships, permissions, and source of truth
- Normal, blocked, pending, conflict, outcome-unknown, success, partial-success, and failure states
- Retry, idempotency, undo, rollback, timeout, and concurrent-change rules
- Cross-component updates, focus movement, announcements, service effects, and analytics
- Safety limits, abuse paths, audit needs, and test scenarios

Do not write large docs for low-risk local actions. Use the light template in [TEMPLATES.md](TEMPLATES.md).

## Place rules at the right layer

| Layer | Owns |
| --- | --- |
| Primitive | Native semantics, focus, keyboard, base states, visual tokens |
| Pattern | Shared confirmation, validation, feedback, and recovery behavior |
| Domain component | Domain labels, valid states, precision, risk, and permissions shown to users |
| Flow controller | Requests, transitions, routing, data refresh, focus restoration, orchestration |
| Server boundary | Final authorization, validation, idempotency, concurrency, durable state |

Keep generic primitives domain-neutral. Do not let each screen recreate domain meaning.

## Implement a vertical slice

1. Start with the highest-risk or most repeated domain action.
2. Make the server mutation safe before adding optimistic UI.
3. Implement the explicit state model and cross-component contract.
4. Connect Tailwind semantic tokens and purposeful Motion behavior.
5. Add focused tests, then drive the full flow in the real app.

Prefer the project's current libraries and patterns. Do not add a state-machine, variant, form, or data library only to follow this skill.

## Required Next.js behavior

- Prefer Server Components for read-only composition and data access.
- Add `"use client"` only for browser APIs, local interaction, or animation.
- Keep final permission and domain validation on the server.
- Handle stale data and concurrent writes with a version, timestamp, ETag, or equivalent check.
- Use an atomic idempotency record scoped to tenant, actor, action, and request payload.
- For a timeout, query the authoritative lifecycle; on `not-found`, resend the same scoped ID and payload, and use a fresh ID only after `failed-no-effect`.

## Required UI behavior

- Use semantic Tailwind tokens instead of repeated raw domain colors and spacing.
- Use Motion to explain state, direction, continuity, or feedback. Remove motion with no clear job.
- Respect reduced motion and keep gesture-driven motion interruptible.
- Preserve keyboard use, logical focus, status announcements, zoom, reflow, and touch targets.
- Make destructive and external effects clear before commitment and recoverable when the service allows it.

## Verify

Run the narrow automated checks first, then the project-wide checks required by the repo.

Exercise at least:

- Normal, blocked, slow, error, and success paths
- Duplicate submit, timeout, outcome unknown, safe retry, and partial success
- Concurrent change from a second session or process
- Keyboard, screen reader, reduced motion, zoom, and touch behavior
- Cross-component updates, analytics, audit events, and service side effects

Do not call the work complete while the model, implementation, and observed flow disagree.

## Final response

Report the system model and invariants, files and behavior changed, findings fixed or deferred, verification performed, and remaining operational risks.
