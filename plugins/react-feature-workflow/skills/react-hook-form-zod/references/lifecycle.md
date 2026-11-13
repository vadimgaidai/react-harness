# Form lifecycle: an edit form across a refetch

How does an edit form fed by a query behave from load to save: initial values, a background refetch mid-edit, a different record, empty versus `null`, `isSubmitting`, field arrays, server errors and `useWatch`?

> Canonical code shape. Replace the placeholders (`[entity]` kebab-case, `[Entity]` PascalCase, `I[Entity]`/`T[Entity]` type identifiers) with real names.

One connected scenario: open an edit form, the query that feeds it is also showing a
background refetch, the user is mid-edit, then saves or hits a server error. Every rule below
is a condition this one component has to satisfy at the same time — the shapes are not
independent.

```tsx
interface I[Feature]EditFormProps {
  id: string
}

const [Feature]EditForm = ({ id }: I[Feature]EditFormProps) => {
  const { data: [entity], isPending } = useQuery([entity]Queries.byId(id))
  const { mutateAsync, isPending: isSaving } = use[Entity]UpdateMutation()

  const form = useForm<T[Feature]FormValues>({
    resolver: zodResolver([feature]Schema),
    values: [entity] && to[Feature]FormValues([entity]),
    resetOptions: { keepDirtyValues: true },
  })

  if (isPending) {
    return <[Entity]FormSkeleton />
  }

  const onSubmit = form.handleSubmit(async (values) => {
    try {
      await mutateAsync(to[Feature]Payload(values))
    } catch (error) {
      const serverField = fieldFromApiError(error)

      if (serverField) {
        form.setError(serverField.name, { type: "server", message: serverField.messageKey })
        return
      }

      form.setError("root.serverError", { message: describe(error).messageKey })
    }
  })

  const serverError = form.formState.errors.root?.serverError?.message

  return (
    <form onSubmit={onSubmit}>
      <FieldGroup>
        <Controller
          name="name"
          control={form.control}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid}>
              <FieldLabel htmlFor={field.name}>{t("[feature].name")}</FieldLabel>
              <Input {...field} id={field.name} aria-invalid={fieldState.invalid} />
              {fieldState.error?.message && <FieldError>{t(fieldState.error.message)}</FieldError>}
            </Field>
          )}
        />
      </FieldGroup>
      {serverError && <Alert variant="destructive">{t(serverError)}</Alert>}
      <SubmitButton isPending={form.formState.isSubmitting || isSaving}>
        {t("actions.save")}
      </SubmitButton>
    </form>
  )
}
```

The form shows the failure, so it is the failure's one owner: `use[Entity]UpdateMutation`
used here does not toast as well (`error-handling`, one owner per notification). Both
`setError` calls store a message key, and the render translates it once; storing `t(...)`'s
result and translating it again on render shows the key's lookup of an already translated
sentence. `fieldFromApiError` and `describe` are the `error-handling` skill's.

## Initial values come from the query, once

`values: [entity] && to[Feature]FormValues([entity])` sets the form's values from the query
the moment data exists, and re-synchronizes on every value RHF receives after that — never an
effect calling `form.reset(entity)` on every render, which fights the user's own edits on each
refetch. `resetOptions: { keepDirtyValues: true }` is what makes that safe: a background
refetch updates the fields the user has not touched and leaves the ones they are mid-edit
alone.

## The edited entity changing is a reset, not a refetch

Navigating this same form to a different `id` is a different scenario from a refetch of the
*same* entity — the form should reset completely, including dirty fields, because it is now
editing something else:

```tsx
<[Feature]EditForm key={id} id={id} />
```

The test for telling these apart: did the identity (`id`) change, or only the data
behind the same identity? A `key` change answers the first; `keepDirtyValues` answers the
second. Confusing them either resets a draft the user is still typing, or keeps stale values
after navigating to a different record.

## `""`, missing, `null` and `0` are four different values

A quantity field means something different in each state, and the schema and payload builder
say which:

```typescript
export const [feature]Schema = z.object({
  quantity: z.string().min(1, "[feature].form.quantityRequired"),
  discountCode: z.string().nullable(),
})
```

`""` on `quantity` is the user having cleared the field — not yet valid, blocks submit. A key
missing from the object altogether means RHF never had a field for it, which only happens
through a `defaultValues` bug. `null` on `discountCode` is an explicit "no value", distinct
from "unanswered" — a nullable select models exactly this. And `0` is a real, valid quantity,
never conflated with "unset". A field whose domain meaning is "not set yet" sends `null` or omits the key in the payload; it
never sends `""` for that meaning, because `""` already means "the user typed nothing, show
the required error."

## `isSubmitting` follows the returned promise

The wrong shape fires the mutation and returns nothing, so `isSubmitting` resolves before the
request does:

```tsx
const onSubmit = form.handleSubmit((values) => {
  mutate(to[Feature]Payload(values))
})
```

The right shape returns the promise, which `handleSubmit` awaits:

```tsx
const onSubmit = form.handleSubmit(async (values) => {
  await mutateAsync(to[Feature]Payload(values))
})
```

`formState.isSubmitting` is `true` for exactly as long as the promise `handleSubmit`'s callback
returns is pending. A callback that fires a mutation and returns `undefined` makes
`isSubmitting` false immediately, so the submit button re-enables before the request finishes.

## Field arrays, server errors, and `useWatch`

`row.id`, React Hook Form's own stable id, is the list key, never the index:

```tsx
const { fields, append, remove } = useFieldArray({ control: form.control, name: "tags" })

{fields.map((row, index) => (
  <Controller
    key={row.id}
    name={`tags.${index}.value`}
    control={form.control}
    render={({ field, fieldState }) => (
      <Field data-invalid={fieldState.invalid}>
        <Input
          {...field}
          aria-label={t("[feature].form.tag", { position: index + 1 })}
          aria-invalid={fieldState.invalid}
        />
        {fieldState.error?.message && <FieldError>{t(fieldState.error.message)}</FieldError>}
        <Button type="button" onClick={() => remove(index)}>
          {t("actions.remove")}
        </Button>
      </Field>
    )}
  />
))}
```

A server-side validation error lands per field (`form.setError("tags.0.value", { message })`)
when the response names a field, or on `root.serverError` for a whole-form failure, never a
second toast on top of it (`error-handling` skill owns which one fires).

A value only one part of the UI needs to re-render on (a live character count, a dependent
field's visibility) is read with `useWatch` in that part. `form.watch()` in the component body
subscribes the whole form component, so every keystroke in any field re-renders all of it; and
under the React Compiler its value goes stale, because the Compiler memoizes around a call it
cannot see change (`react` skill, APIs the Compiler skips). `useWatch` subscribes only the
component that reads it.
