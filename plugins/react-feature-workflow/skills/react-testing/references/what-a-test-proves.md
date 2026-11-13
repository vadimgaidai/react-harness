# What a test proves, rule by rule

Answers: why each rule in `SKILL.md` holds, and where its line falls when a case looks like an exception.

## The observable result

A test asserts the observable result of a user action (what is on screen, what request body was sent), never an implementation detail: a state variable's value, a call count on a function internal to the component under test.

## Queries and translations

A test finds an element by its role and accessible name, the way a user and a screen reader
find it; `getByTestId` passes on a button with no name and an input with no label, which the UI
rules forbid. The text it matches is the real translation, so a missing key fails the test
instead of rendering `"actions.save"` on screen. Shapes: [setup.md](setup.md).

## What is mocked

The behaviour under test is not mocked away. Mock the network boundary (the HTTP client, an MSW handler) so the real hook and the real component run; a test that mocks the hook under test only proves the mock was called.

A query-backed component is tested through a real `QueryClient` with retries off, so a test failure does not wait out the retry backoff. A mocked `useQuery` return value stops testing the states `tanstack-query` actually produces, and says nothing about whether the component asked for the right key. The production client's own retry policy is `tanstack-query`'s concern, not the test's.

## Async UI

Async UI is awaited through the testing library's own queries (`findBy*`, `waitFor`), never a fixed `setTimeout` or arbitrary sleep, which is both slower than necessary and still racy.

## States beyond success

Pending, failure, and the retry after a failure each get their own test. A suite that only covers the happy path proves nothing about what the user sees when the request is slow or fails.

## Forms

A form test types into the fields, submits, and asserts both the rendered error text and the payload the mocked network boundary actually received, not just that `onSubmit` fired. Shapes: [form-and-unmount.md](form-and-unmount.md).

## The URL

A component whose state lives in the URL is tested from a URL, inside the real router. Passing
the filters as props or mocking the router's hook skips the parsing, the merge and the
loader, which are where URL bugs live. Shapes: [url-state.md](url-state.md).

## Cleanup

Cleanup is tested where it matters: unmount the component and assert the subscription, timer or listener it held is actually gone, not just that unmount did not throw. A component that subscribes without returning a cleanup passes every other test in the suite and fails only this one; the cleanup rule itself is `react`'s.

## Real evidence, not a stub

A passing check is a real run of the project's runner over real assertions. A script that prints `PASS` without asserting anything is a fixture, not evidence; a review of a test file says which one it is looking at before citing it as a passing check.

## Who writes tests

`verify` runs existing tests and writes none; `implement` or the user writes tests where the project has a runner, and this skill guides what they assert and how `review` reads them.
