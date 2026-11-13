# Reviewing: react-hook-form-zod

Answers: what `review` asks of a hunk this skill governs. `review` reads this file when it starts; writing code does not need it.

In order of how often it hurts:

- a hand-written interface duplicating `z.infer`
- `z.input` diverging from `z.output` on a form schema (a `.transform`/`.preprocess`, or an unreconciled `z.coerce` field)
- a `<form action>` / `useActionState` / `useFormStatus` on an RHF form
- manual `onChange` validation instead of letting the resolver run
- a raw `div` in place of `Field`/`FieldGroup`/`FieldLabel`/`FieldDescription`/`FieldError`, or an error rendered in `FieldDescription`
- a field outside `Controller`, or a `Field` without `data-invalid` and a control without `aria-invalid` from `fieldState.invalid`
- `t()` called with a possibly `undefined` message, or a translated sentence stored by `setError` and translated again on render
- a chained Zod 3 format (`z.string().email()`) or `message` option in a Zod 4 project
- an error message that is literal text instead of a `t()` key
- a submit button that swaps its label instead of keeping it and showing a `Spinner`
- `reset()` called from an effect on every refetch, erasing fields the user is mid-edit on, instead of `values` + `keepDirtyValues` (and a `key` change when the edited entity changes)
- `isSubmitting` read from a submit handler that does not await or return the mutation's promise
- `""` sent for a field that means "not set" — `null` or an omitted key was meant
- a field array keyed by index instead of `useFieldArray`'s own `field.id`
- a server-side field error surfaced as a second toast instead of `setError`
- `form.watch()` read in the component body where `useWatch` was meant: it re-renders the whole form and goes stale under the Compiler
- no `defaultValues` on a controlled field, risking an uncontrolled→controlled warning
