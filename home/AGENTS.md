# Global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
- Never use a long word where a short one will do.
- If it is possible to cut a word out, always cut it out.
- Never use the passive where you can use the active.
- Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
- Break any of these rules sooner than say anything outright barbarous.

# Multi-agent convergence protocol

Use this protocol whenever the user asks for multiple agents, parallel review,
or principal-level auditing.

### Treat delegation as a verification loop

Parallel agreement is evidence, not proof. Sub-agents often share the same
context, model family, assumptions, and blind spots. The root agent remains
responsible for validating every finding and for the correctness of the final
integrated diff.

1. Define a review contract before spawning agents:
   - Give each agent a distinct boundary or failure class.
   - State whether the task is read-only or allows edits.
   - Ask for concrete file/line evidence, severity, and a proposed verification.
   - For security, persistence, or concurrency work, explicitly ask about
     rollback, deletion, retries, multi-process behavior, resource exhaustion,
     and abuse paths.

2. Review a stable snapshot:
   - When agents are reviewing existing changes, do not mutate those same files
     until the initial reviewers finish.
   - If useful local work can proceed, keep it independent of the reviewed diff.
   - Record the reviewed git state or clearly tell agents to inspect the current
     working tree immediately before reporting.

3. Synthesize findings into a disposition ledger before implementing:
   - Track each actionable finding as `accepted`, `rejected`, or `deferred`.
   - Preserve severity and evidence.
   - For rejected findings, verify the reason independently; do not dismiss them
     merely because another agent did not report the same issue.
   - Do not claim the review is clean while accepted high-severity findings or
     required verification remain open.

4. Implement fixes under explicit invariants:
   - State what must remain true after the fix.
   - Prefer fixing the shared root cause over applying several local patches.
   - Add a regression test that fails for the reported bug when practical.
   - Treat green tests as necessary but insufficient for concurrency, security,
     migration, and distributed-system claims.

5. Require final-diff re-review after material fixes:
   - Send the updated diff back to the original specialist agents.
   - Ask whether their finding is actually resolved and what new failure mode
     the repair may have introduced.
   - Re-run focused checks after addressing second-pass findings.
   - A multi-agent audit is complete only when the root checks are green and the
     relevant specialists find no remaining release blocker, or the root clearly
     reports the unresolved blocker to the user.

6. Detect failed convergence:
   - If a second-pass repair produces another issue in the same risk class, stop
     patching locally and redesign that mechanism from its invariants.
   - Do not keep adding reviewers merely to manufacture consensus. Use another
     review round only to verify a changed implementation or investigate a newly
     discovered boundary.

In the final response, distinguish: findings fixed, findings intentionally
deferred, verification performed, and residual operational risks.
