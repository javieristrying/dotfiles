# UI Systems Templates

Use project naming and documentation conventions first. These templates are fallbacks.

## 1. Light action model

Use for low-risk local actions.

```markdown
# Action: [Name]

- User goal:
- Domain object:
- Allowed starting states:
- Main and secondary actions:
- Pending, success, and error behavior:
- Components and data that update:
- Focus and announcement behavior:
- Test scenarios:
```

## 2. Full action model

Use when an action affects money, privacy, permissions, ownership, external services, several users, or hard-to-reverse state.

```markdown
# System Action: [Name]

## Outcome
- User goal:
- Product or service outcome:
- Why it matters:

## Actors and objects
- Main actor:
- Other roles:
- Main domain object:
- Related objects:
- Relationships:

## Rules
- Preconditions:
- Permissions:
- Policy limits:
- Final source of truth:
- Rules previewed by the UI:

## States
- Starting:
- Blocked or invalid:
- Confirming:
- Pending:
- Outcome unknown:
- Conflict or stale data:
- Success:
- Partial success:
- Retryable error:
- Final error:
- Undo available or expired:

## Actions and recovery
- Primary action:
- Secondary actions:
- Destructive actions:
- Confirmation:
- Safe retry rule:
- Idempotency scope and payload hash:
- Authoritative request lifecycle and result lookup:
- Compensating undo:
- Internal rollback:
- Irreversible effects:

## Cross-component effects
- Components that update:
- Data that refreshes:
- Navigation change:
- Focus destination:
- Announcements:
- Other users or services affected:

## Service dependencies
- Server mutation:
- Backstage systems:
- Partial failure points:
- Concurrency check:
- Transaction boundary:
- Outbox or side-effect delivery:
- Dependency owner:

## Safety and limits
- Duplicate request behavior:
- Rate or bulk limit:
- Queue or cost limit:
- Notification deduplication:
- Audit and abuse response:

## Measurement
- Product question:
- Analytics events:
- Task success:
- Comprehension:
- Recovery measure:

## Scenarios
- Normal:
- No permission:
- Invalid state:
- Slow request:
- Timeout and outcome unknown:
- Concurrent change:
- Partial success:
- Safe retry:
- Undo expired:
- Accessibility paths:
```

## 3. State transition table

```markdown
| Current state | Event | Guard or rule | Next state | Server effect | UI effect |
| --- | --- | --- | --- | --- | --- |
| idle | START | allowed | confirming | none | open confirmation |
| confirming | CONFIRM | version current | pending | send request | show progress |
| confirming | CONFIRM | version stale | conflict | fetch current | show changed state |
| pending | SUCCESS | none | success | commit | update connected UI |
| pending | TIMEOUT | result unknown | outcome-unknown | query request | block fresh retry |
| outcome-unknown | STATUS_IN_PROGRESS | unresolved | outcome-unknown | check again later | keep waiting |
| outcome-unknown | STATUS_NOT_FOUND | authoritative record absent | outcome-unknown | resend same scoped ID and payload | keep fresh retry blocked |
| outcome-unknown | STATUS_COMPLETED | completed | success | none | show server state |
| outcome-unknown | STATUS_PARTIAL | core committed | partial-success | repair effects | show mixed result |
| outcome-unknown | STATUS_FAILED_NO_EFFECT | terminal with no change | retryable-error | none | allow a fresh request |
| pending | FAILURE | durable failed-no-effect | retryable-error | none | explain and retry |
```

## 4. Cross-component contract

```markdown
# Contract: [Domain event]

## Event
- Object:
- Old state:
- New state:
- Request or event ID:

## Required UI updates
- [Component A]:
- [Component B]:
- [Component C]:

## Data
- Update from mutation result:
- Refetch:
- Keep:
- Conflict check:

## Navigation and accessibility
- Route change:
- Focus destination:
- Status announcement:
- Reduced-motion result:

## Failure and recovery
- State that stays unchanged:
- Internal rollback:
- Safe retry:
- Compensating undo:
- Partial-success repair:

## Measurement
- Event:
- Properties:
- Privacy limits:
```

## 5. Layer ownership table

```markdown
| Rule or behavior | Primitive | Pattern | Domain | Flow | Server |
| --- | --- | --- | --- | --- | --- |
| Keyboard activation | X |  |  |  |  |
| Confirmation layout |  | X |  |  |  |
| Domain risk label |  |  | X |  |  |
| Request state |  |  |  | X |  |
| Final permission |  |  |  |  | X |
| Idempotency |  |  |  |  | X |
```

## 6. Next.js implementation map

```markdown
# Implementation Map

## Route and composition
- Route:
- Server Components:
- Client boundary:

## Domain
- Types:
- Validation:
- Permission service:
- Version or concurrency value:

## Mutation
- Server Action or Route Handler:
- Idempotency scope, including tenant, actor, action, and request ID:
- Immutable payload hash:
- Atomic claim or create operation:
- Lifecycle states: in-progress, completed, failed-no-effect, partial
- Transaction boundary for the domain result:
- Outbox for external side effects:
- Authenticated and scoped result lookup from the durable primary store:
- `not-found` resend using the same request ID and payload:
- Data refresh after terminal result:

## UI
- Primitive changes:
- Pattern changes:
- Domain component changes:
- Flow controller:

## Tailwind
- Semantic tokens:
- Domain state mapping:
- Responsive and reflow behavior:

## Motion
- Purpose:
- State that drives animation:
- Reduced-motion behavior:
- Focus timing:

## Tests
- Unit:
- Component:
- Integration:
- End-to-end:
```

## 7. Review ledger

Use this after reviews or audits.

```markdown
| Finding | Severity | Evidence | Decision | Fix or reason | Verification |
| --- | --- | --- | --- | --- | --- |
|  |  |  | accepted / rejected / deferred |  |  |
```

Do not call a review clean while accepted high-severity findings or required checks remain open.
