# Examples

These examples show structure. Adapt names, libraries, and data access to the project.

## Example: cancel appointment

### System model

```text
Outcome:
Cancel one scheduled appointment and free the slot when policy allows.

Rules:
- User owns the appointment or has staff permission.
- Appointment must still be scheduled.
- Expected version must match the server version.
- Request identity is scoped by tenant, actor, and action.
- Reusing a key with a different payload is rejected.
- The request record is claimed atomically before the appointment changes.

States:
idle -> confirming -> pending
pending -> success | conflict | outcome-unknown | partial-success | error
outcome-unknown -> outcome-unknown | success | conflict | partial-success | error
success -> undo-available -> restoring -> restored | undo-expired
```

### Server result type

```ts
type CancelAppointmentInput = {
  appointmentId: string;
  expectedVersion: number;
  requestId: string;
};

type CancelAppointmentResult =
  | { status: "in-progress"; requestId: string }
  | { status: "cancelled"; appointment: Appointment }
  | { status: "conflict"; appointment: Appointment }
  | { status: "partial"; appointment: Appointment; pendingEffects: string[] }
  | { status: "not-allowed"; reason: string }
  | { status: "failed-no-effect"; message: string }
  | { status: "payload-mismatch"; message: string };

type CancellationRequestStatus =
  | CancelAppointmentResult
  | { status: "not-found" };
```

### Server mutation sketch

```ts
"use server";

export async function cancelAppointment(
  input: CancelAppointmentInput,
): Promise<CancelAppointmentResult> {
  const user = await requireUser();
  const scope = {
    tenantId: user.tenantId,
    actorId: user.id,
    action: "cancel-appointment",
    requestId: input.requestId,
  };
  const payloadHash = hashMutationPayload({
    appointmentId: input.appointmentId,
    expectedVersion: input.expectedVersion,
  });

  return db.transaction(async (tx) => {
    const claim = await mutationRequests.claim({ scope, payloadHash, tx });

    if (claim.kind === "payload-mismatch") {
      return { status: "payload-mismatch", message: "Request ID was reused with different data" };
    }

    if (claim.kind === "existing") {
      return claim.result;
    }

    const appointment = await appointments.findForUpdate(input.appointmentId, tx);
    if (!appointment) {
      return mutationRequests.finishNoEffect(scope, "Appointment not found", tx);
    }

    if (!canCancel(user, appointment)) {
      return mutationRequests.finishNotAllowed(scope, "This appointment cannot be cancelled", tx);
    }

    if (appointment.version !== input.expectedVersion) {
      return mutationRequests.finishConflict(scope, appointment, tx);
    }

    const cancelled = await appointments.cancel(appointment, tx);
    await outbox.enqueue({ type: "appointment-cancelled", appointmentId: cancelled.id }, tx);

    return mutationRequests.finishCompleted(
      scope,
      { status: "cancelled", appointment: cancelled },
      tx,
    );
  });
}
```

`mutationRequests.claim` must use a unique scoped key and an atomic insert or claim. The appointment change and terminal request result commit together. External effects use an outbox so they do not repeat the core mutation.

### Client flow state

```ts
type State =
  | { value: "idle" }
  | { value: "confirming" }
  | { value: "pending"; request: CancelAppointmentInput }
  | { value: "outcome-unknown"; request: CancelAppointmentInput }
  | { value: "conflict"; appointment: Appointment }
  | { value: "success"; appointment: Appointment }
  | { value: "partial-success"; appointment: Appointment; pendingEffects: string[] }
  | { value: "error"; retryable: boolean; message: string };
```

Do not replace this with several booleans that allow impossible combinations.

### Authoritative result lookup

```ts
export async function getCancellationRequestStatus(
  requestId: string,
): Promise<CancellationRequestStatus> {
  const user = await requireUser();

  const result = await mutationRequests.findScopedFromPrimary({
    tenantId: user.tenantId,
    actorId: user.id,
    action: "cancel-appointment",
    requestId,
  });

  return result ?? { status: "not-found" };
}
```

The lookup repeats authentication and scope and reads the durable primary store. It always returns an explicit lifecycle state, including `not-found`, `in-progress`, `cancelled`, `partial`, or `failed-no-effect`.

### Outcome unknown handling

```ts
async function resolveUnknownResult(request: CancelAppointmentInput) {
  const result = await getCancellationRequestStatus(request.requestId);

  switch (result.status) {
    case "not-found": {
      const replay = await cancelAppointment(request);
      return applyResult(replay);
    }
    case "in-progress":
      scheduleStatusCheck(request);
      return;
    case "cancelled":
    case "partial":
    case "conflict":
    case "not-allowed":
    case "payload-mismatch":
      return applyResult(result);
    case "failed-no-effect":
      setState({ value: "error", retryable: true, message: result.message });
  }
}
```

Keep a fresh request blocked while the lifecycle is unresolved. If the durable record is `not-found`, resend the same scoped request ID and identical payload through the atomic mutation path. Offer a fresh request ID only after `failed-no-effect`. Do not infer success or failure from appointment status alone.

### Domain component

```tsx
type AppointmentStatusProps = {
  status: "scheduled" | "cancelled" | "completed";
};

const styles = {
  scheduled: "bg-status-info-subtle text-status-info",
  cancelled: "bg-status-muted-subtle text-status-muted",
  completed: "bg-status-success-subtle text-status-success",
};

export function AppointmentStatus({ status }: AppointmentStatusProps) {
  const label = {
    scheduled: "Scheduled",
    cancelled: "Cancelled",
    completed: "Completed",
  }[status];

  return <span className={styles[status]}>{label}</span>;
}
```

The domain mapping exists once. Screens do not choose arbitrary colors or labels.

### Motion with a clear purpose

```tsx
import { motion, useReducedMotion } from "motion/react";

export function AppointmentPanel({ state }: { state: State }) {
  const reduceMotion = useReducedMotion();

  return (
    <motion.section
      layout
      transition={reduceMotion ? { duration: 0 } : { duration: 0.2, ease: "easeOut" }}
      aria-busy={state.value === "pending"}
    >
      {/* Render the state-specific content here. */}
    </motion.section>
  );
}
```

If the project uses `framer-motion`, keep its existing import style.

The layout animation explains a size change in the same panel. It does not delay the server result.

### Cross-component contract

```text
When cancellation succeeds:
- AppointmentStatus shows Cancelled.
- AppointmentActions removes Join, Reschedule, and Cancel.
- CalendarEvent uses the cancelled state.
- AppointmentList updates the same object.
- NotificationStatus shows pending or delivered.
- Focus moves to AppointmentStatus after the dialog closes.
- A polite status message announces the result.
```

### End-to-end scenarios

```text
1. Cancel a valid appointment, then change it in a second session before another confirmation.
2. Send the same scoped key concurrently and confirm one atomic claim and one cancellation.
3. Reuse the key from another actor or with another payload and confirm rejection without data exposure.
4. Drop the client response, test `in-progress`, and test `not-found` by resending the same ID and payload.
5. Fail an outbox effect and test partial status, repair, safe retry, and undo expiry.
```
