# UI Systems Reference for Next.js

## 1. The work unit

Use a domain action as the main design and implementation unit.

```text
Actor + object + goal + rules + states + effects + feedback + recovery
```

Examples:

- Cancel appointment
- Approve expense
- Publish article
- Transfer ownership
- Withdraw collateral

A Button may start the action. It is not the full action.

## 2. Four UI layers

### Primitive

Examples: Button, Input, Dialog, Menu.

Owns:

- Native element choice
- Keyboard and pointer behavior
- Focus appearance
- Base disabled and pending appearance
- Accessible name, role, and state support

Does not own domain permission or policy.

### Pattern

Examples: confirmation flow, form validation, recoverable deletion.

Owns:

- Action order
- Shared feedback placement
- Confirmation structure
- Common retry or undo presentation
- Accessibility behavior shared by several features

### Domain component

Examples: HealthFactor, AppointmentStatus, ApprovalState.

Owns:

- Domain terms
- Valid states
- Risk or status meaning
- Precision and rounding shown to users
- Consistent domain explanations

### Product flow

Owns:

- Server request and result handling
- State transitions
- Cross-component updates
- Routing and focus restoration
- Analytics and audit connections

## 3. Next.js boundaries

### Server Components

Use for:

- Reading server data
- Permission-aware composition
- Rendering stable content
- Keeping secrets and private dependencies on the server

Do not add `"use client"` only because a descendant is interactive. Keep the client boundary as small as practical.

### Client Components

Use for:

- Local interaction state
- Browser APIs
- Gestures
- Motion animation
- Immediate form feedback

A Client Component must not become the final authority for permissions or financial rules.

### Mutations

Use the project's existing mutation boundary, such as a Server Action or Route Handler.

The server must repeat:

- Authentication and tenant or account scope
- Authorization and domain validation
- Concurrency checks
- Atomic idempotency checks
- Durable result recording

Client validation improves feedback. It does not protect the system.

### Idempotency protocol

For an important mutation, define one durable request record.

Scope its unique key by:

- Tenant or account
- Authenticated actor
- Action name
- Client request ID

Bind the record to a hash of immutable request data, such as the object ID, expected version, and intended action. Reject the same key when the payload hash changes.

Create or claim the record atomically before the domain change. Use explicit lifecycle states:

```text
in-progress
completed
failed-no-effect
partial
```

Where practical, commit the domain transition and terminal request result in one database transaction. Put external effects, such as notifications, into an outbox so workers can process them without repeating the core mutation.

Result lookup must repeat authentication and use the same tenant, actor, and action scope. Never look up a result by a caller-controlled request ID alone.

### Data refresh

After a mutation, define which data must:

- Update immediately from the result
- Revalidate or refetch
- Stay unchanged
- Show a temporary pending state
- Resolve a conflict with newer server data

Do not refresh the whole route when a smaller correct update exists, unless the project favors route revalidation for reliability.

## 4. Async state model

Use explicit states. Avoid unrelated boolean combinations.

Recommended starting states:

```text
idle
blocked
invalid
confirming
pending
outcome-unknown
conflict
success
partial-success
retryable-error
final-error
undo-available
undo-expired
restoring
```

Delete states that do not apply. Add domain states when needed.

### Outcome unknown

Use when the client timed out or disconnected after the server may have completed the action.

Required behavior:

1. Keep the scoped request ID and immutable payload.
2. Query the authoritative request lifecycle from the primary durable store, not a cache or delayed replica.
3. Stay blocked while the request is `in-progress` or not yet resolved.
4. Apply `completed` or `partial` results without inferring them from object state alone.
5. Offer a fresh request ID only after a durable `failed-no-effect` result.

If the authoritative lookup returns `not-found`, resend the same scoped request ID and identical payload through the atomic mutation path. The server will create the one request if none arrived, or return the existing record if another copy won the race.

Refresh the affected object after the request reaches a terminal state. Do not treat a missing cache entry or unchanged object as proof that the request failed.

### Concurrent change

Use a version, updated timestamp, ETag, revision, or domain-specific lock.

When a conflict happens:

- Do not overwrite silently.
- Show what changed.
- Refresh the object.
- Ask the user to review the current state.
- Preserve safe input when practical.

## 5. Retry, undo, and rollback

### Retry

Repeats the same intended request.

A safe retry needs:

- A durable `failed-no-effect` result, or reuse of the same scoped idempotency record
- An identical payload hash
- Clear retry limits
- Stable request meaning
- No unresolved `in-progress` request

### Undo

Starts a new action that compensates for the first result.

Define:

- Time limit
- Preconditions
- External effects that cannot be reversed
- What happens when undo fails
- Whether another actor can block undo

### Rollback

Restores internal state after an incomplete operation.

Do not present internal rollback as a user-facing promise unless the full service can honor it.

## 6. Tailwind CSS rules

### Use semantic tokens

Prefer names based on purpose:

```css
--color-surface-danger
--color-text-muted
--color-action-primary
--space-control-gap
--radius-control
```

Map tokens into the project's Tailwind setup. Follow the project's version and configuration style.

Avoid spreading raw domain colors through JSX:

```tsx
className="text-red-600 bg-red-50"
```

Prefer one domain mapping:

```tsx
const toneByRisk = {
  safe: "text-risk-safe bg-risk-safe-subtle",
  warning: "text-risk-warning bg-risk-warning-subtle",
  danger: "text-risk-danger bg-risk-danger-subtle",
}
```

Keep the mapping in the domain component or shared domain style, not in every screen.

### Component variants

Use the project's existing variant method. This may be plain functions, `clsx`, `tailwind-merge`, or a variant library.

Do not add a new variant library for one component.

Prevent invalid combinations at the type and API level when practical.

## 7. Motion rules

Use the installed Motion package and import style. Current projects may use `motion/react`; older projects may still use `framer-motion`.

Motion needs one clear job:

- Explain where content came from
- Preserve object identity
- Show navigation direction
- Confirm state change
- Guide attention to the next useful place

### State-based animation

Drive animation from domain or flow state, not scattered local booleans.

```tsx
<motion.div
  animate={state === "success" ? "success" : "idle"}
  variants={variants}
/>
```

### Layout animation

Use layout animation when the same object changes position or size.

Keep one object identity. Do not fade out one copy while fading in another when the object persists.

### Exit animation

Use presence animation only when an exit helps the user follow the change.

After removal:

- Move focus first or as part of the controlled change.
- Avoid delaying an urgent server result only for animation.
- Keep exit durations short in repeated workflows.

### Reduced motion

Respect the user's reduced-motion preference.

Reduce or remove:

- Large travel distance
- Parallax
- Repeated loops
- Strong scale changes
- Motion needed only for decoration

Do not remove important state feedback. Replace motion with a clear instant state change when needed.

## 8. Accessibility across the flow

Check more than the primitive.

### Focus

Define focus for:

- Opening a dialog
- Closing a dialog
- Successful deletion
- Failed submission
- Added or removed content
- Route changes
- Conflict and outcome-unknown resolution

### Announcements

Use the project's accessible status pattern for:

- Pending work when delay matters
- Validation errors
- Request failures
- Successful completion when not otherwise clear
- External changes from another actor

Do not announce every visual update.

### Full-flow checks

Test:

- Keyboard only
- Screen reader
- Touch target size
- 200% and 400% zoom or reflow
- Reduced motion
- Time limits and expiring undo

## 9. Safety and operational limits

For important actions, inspect:

- Duplicate request behavior
- Rate and bulk limits
- Queue and cost limits
- Notification deduplication
- Audit history
- Abuse against another user
- Resource exhaustion

The UI must explain user-facing limits. The server must enforce system limits.

## 10. Analytics

Start with a product question.

Example:

```text
Question: Do users understand the cancellation fee?
```

Then define the smallest useful events:

```text
cancellation_confirmation_viewed
cancellation_abandoned_after_fee
cancellation_completed
```

Do not collect sensitive values without a clear need and approved handling.

Analytics do not replace user research. They show what happened, not always why.

## 11. Testing strategy

### Unit tests

Use for:

- Domain mapping
- State transitions
- Formatting and precision
- Permission display rules
- Invalid prop or state prevention

### Component tests

Use for:

- Keyboard behavior
- Focus movement
- Announcements
- Validation and error display
- Motion-independent state results

### Integration tests

Use for:

- Atomic claim under concurrent requests
- Tenant, actor, action, and payload scoping
- Authoritative request lifecycle and outcome-unknown resolution
- Conflict handling and data refresh
- Outbox delivery, partial success, and repair

### End-to-end tests

Drive the real flow for:

- Normal completion
- Blocked action
- Timeout with outcome unknown
- Concurrent update from a second session
- Safe retry and undo expiry

## 12. Definition of done

The work is done when:

- The model and implementation use the same states.
- Domain rules have clear owners.
- Connected components update together.
- Failure and recovery work in the real app.
- Accessibility checks cover the full flow.
- Tests cover the highest-risk paths.
- Remaining service or operational risks are reported.
