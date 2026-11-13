---
name: react-hook-form-zod
description: Forms with React Hook Form and Zod — useForm with zodResolver, the schema file and its z.infer type, z.input matching z.output, Field/FieldGroup/FieldError layout, Controller with data-invalid and aria-invalid, Zod 4 formats, useFieldArray, submit and isSubmitting, an edit form's values across a refetch, setError. Use when writing or fixing a form, a validation schema, a field array, a multi-step form, a submit handler, or a resolver type error.
---

# React Hook Form + Zod

- The schema lives in its own file, never inline in a component or an API file, so the form, the mutation and the tests import one schema and its `z.infer` type; placement is the structure skill loaded in this project.
- The form type is `z.infer<typeof schema>`, exported next to the schema, never a hand-written interface that can drift from it.
- A form schema keeps `z.input` equal to `z.output`: no `.transform`, `.preprocess` or `z.coerce`, because `zodResolver` types the form by the output while `defaultValues` and the fields work on the input; conversion happens in `onSubmit`.
- A schema message is a translation key, and every label and message renders through `t("key")`.
- Zod 4 is written in its own forms (`z.email("key")`, `z.url()`, the `error` parameter); check `package.json` once, since Zod 3 uses the chained ones ([references/schemas.md](references/schemas.md) has the table).
- No schema pattern without a precedent in [references/schemas.md](references/schemas.md) or in the repo.
- `useForm` takes `zodResolver(schema)` and `defaultValues` for every field, so no field starts `undefined` and switches from uncontrolled to controlled.
- The resolver is the only validation; no manual `onChange` checks.
- Every field goes through `Controller`, as shadcn's form docs do, so every control has one shape and `fieldState` at hand: `{...field}` on the control, `fieldState.invalid` as `data-invalid` on `Field` and `aria-invalid` on the control.
- Layout is `FieldGroup`, `Field`, `FieldLabel`, `FieldDescription` for help text and `FieldError` for the error (`{fieldState.error?.message && <FieldError>{t(fieldState.error.message)}</FieldError>}`), array rows included; never raw `div`s, never the legacy `Form`/`FormField`/`FormItem`, which shadcn's current form docs replace with `Field` and `Controller`. Visual layout beyond `Field` is `ui-conventions`.
- A field array goes through `useFieldArray` and is keyed by `field.id`, never the index.
- The submit target is a mutation hook from the module's mutations file, and `handleSubmit`'s callback awaits or returns its promise, since `isSubmitting` lasts exactly as long as that promise.
- The submit button keeps its label, takes `disabled={isSubmitting || mutation.isPending}` and shows a `Spinner` with `data-icon="inline-start"`.
- No `<form action>`, `useActionState` or `useFormStatus` on an RHF form, one-field forms included: the action wins the submit event and the resolver never runs.
- An edit form takes its values from the query through `values` with `resetOptions: { keepDirtyValues: true }`, never a `reset` effect; a different entity resets through `key`.
- `""`, a missing key, `null` and `0` are four values; "not set" is sent as `null` or an omitted key, never `""`.
- A server error the response ties to a field goes to `setError` on that field, anything else to `root.serverError`, each with a message key; the form that shows it is its one owner, so no toast beside it (`error-handling`).
- A value one part of the UI re-renders on is read with `useWatch`, not `form.watch()`, since `watch()` re-renders the whole form on every change and its value goes stale under the React Compiler.
- A multi-step form is step components sharing one form through `FormProvider`.

## Example

A number field. `z.coerce` makes the input `unknown` while the output is `number`:

```typescript
export const [feature]Schema = z.object({
  quantity: z.coerce.number().min(1, "[feature].form.quantityRequired"),
})
```

The field stays a string and becomes a number where the payload is built:

```typescript
export const [feature]Schema = z.object({
  quantity: z.string().refine((value) => !Number.isNaN(Number(value)), "[feature].form.quantityInvalid"),
})

const onSubmit = form.handleSubmit(async (values) => {
  await mutateAsync({ ...values, quantity: Number(values.quantity) })
})
```

## References

- [references/form.md](references/form.md): writing a form component from scratch: the recipe, a field through `Controller` with its error state, the submit button, multi-step, why a React 19 form action is not used, and versions.
- [references/schemas.md](references/schemas.md): writing or changing a schema: a new schema, `.extend`, a number field, env validation, and Zod 3 against Zod 4.
- [references/lifecycle.md](references/lifecycle.md): an edit form fed by a query: initial values, a refetch mid-edit, a changed entity, empty versus `null`, `isSubmitting`, field arrays, server errors, `useWatch`.
- Anything none of these covers: the current upstream docs through the `context7` MCP server (`/react-hook-form/react-hook-form`, `/colinhacks/zod`), not a guess.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
