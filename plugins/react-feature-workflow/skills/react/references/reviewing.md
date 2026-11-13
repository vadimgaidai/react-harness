# Reviewing: react

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- a redundant effect — any shape in [references/effects.md](effects.md)
- state above the only subtree that reads it, or duplicating cached server data
- a mutation, toast, navigation or storage write during render
- props, state or query data mutated in place instead of copied
- a scan over a second collection repeated per rendered item
- a memo whose deps churn, or a `useMemo`/`useCallback` that buys neither real work nor a stable reference something depends on
- an index key on a dynamic list, a component defined inside another's render, or a `key` that changes for the wrong reason — each resets state the user did not ask to lose
- a subscription, timer or listener with no cleanup, or a `hasRun` flag standing in for one
- a stale async result (a late search or save) rendered over a screen that has since changed
- two state flags that can both be true where a union of states was meant
- a context whose value churns every render
- a route, modal or heavy widget imported eagerly
- a Suspense boundary with no error boundary beside it, or a retry that re-throws the same cached error or rejection instead of resetting
- a ref read during render
- `Date.now()`, `new Date()`, `Math.random()` or a global write in the body of a component
- a numeric JSX condition (`{items.length && …}`) that renders `0`
- an effect that re-runs because a value only its event reads is a dependency, a ref kept to hold the latest value, or a dependency left out behind `eslint-disable … react-hooks/exhaustive-deps` where `useEffectEvent` was meant
- any `eslint-disable` of a `react-hooks/*` rule: the diagnostic it hides is the finding
- a tab or panel that loses typed input when hidden, where `<Activity>` was meant
- an expensive list re-rendered on every keystroke of the input that filters it, with no `useDeferredValue`
