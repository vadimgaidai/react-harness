# A form test through submit, error and payload

Answers: how to test a form end to end (typed values, the payload sent, the server's field error) and its submit button while the mutation is pending.

> Canonical code shape. Replace the placeholders (`[feature]`) with real names. Shown for
> Vitest + React Testing Library + MSW + `user-event`, rendered with `renderWithProviders` and
> the real translations ([setup.md](setup.md)).

```tsx
test("submits the typed values and shows the server's field error on failure", async () => {
  const user = userEvent.setup()
  let receivedBody: unknown

  server.use(
    http.post("/api/[feature]", async ({ request }) => {
      receivedBody = await request.json()
      return HttpResponse.json({ field: "email", message: "[feature].form.emailTaken" }, { status: 409 })
    })
  )

  renderWithProviders(<[Feature]Form />)

  await user.type(screen.getByLabelText(/email/i), "taken@example.com")
  await user.type(screen.getByLabelText(/password/i), "a-real-password")
  await user.click(screen.getByRole("button", { name: /save/i }))

  expect(await screen.findByText(/email is already in use/i)).toBeInTheDocument()
  expect(receivedBody).toEqual({ email: "taken@example.com", password: "a-real-password" })
})
```

Three things this one test proves that a looser one would miss: the payload actually sent
(not just that `onSubmit` was called), the server error translated into the field's own
`FieldError` rather than a toast (`error-handling`'s "one owner" rule, tested), and the
button's label (`Save`) still present rather than swapped for a loading word mid-flight —
query it by its stable accessible name throughout, not by text that changes with `isPending`.

## Pending state without losing the button

```tsx
test("disables the submit button while the mutation is in flight, without hiding its label", async () => {
  const user = userEvent.setup()
  server.use(
    http.post("/api/[feature]", async () => {
      await delay("infinite")
      return HttpResponse.json({})
    })
  )

  renderWithProviders(<[Feature]Form />)
  await user.type(screen.getByLabelText(/email/i), "a@b.com")
  await user.click(screen.getByRole("button", { name: /save/i }))

  expect(screen.getByRole("button", { name: /save/i })).toBeDisabled()
})
```

The button is found by the same accessible name before and during the pending state — a test
that instead queries for a different string while pending (`"Saving..."`) would pass even if
the component silently violated the "keep the label" rule, because it never looks for the
label it is supposed to keep.

`delay("infinite")` keeps the request open for the whole test, so the assertion runs while
the mutation is pending; a fixed `delay(50)` races the assertion against the response.
