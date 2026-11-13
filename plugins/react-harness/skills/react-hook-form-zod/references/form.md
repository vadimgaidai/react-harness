# The form component

How is a form component wired from scratch: `useForm`, a field through `Controller` with its error state, the submit button, a multi-step form, why a React 19 form action has no place on it, and which versions change what?

> Canonical code shape. Replace the placeholders (`[feature]` kebab-case, `[Feature]` PascalCase, `I[Feature]`/`T[Feature]` type identifiers) with real names. Primitives come from wherever `components.json` puts them.

## The recipe

```tsx
const form = useForm<T[Feature]FormValues>({
  resolver: zodResolver([feature]Schema),
  defaultValues: { email: "", password: "" },
})
```

`defaultValues` is always given, for every field, because a field that starts `undefined` and then gets a value switches React from uncontrolled to controlled and warns.

## A field

Every field goes through `Controller`, the shape shadcn's form docs use. One shape serves an `Input`, a `Textarea`, a `Select`, a `Checkbox` or a `DatePicker`, and `fieldState` carries the error state without reading `formState.errors` by path:

```tsx
<FieldGroup>
  <Controller
    name="email"
    control={form.control}
    render={({ field, fieldState }) => (
      <Field data-invalid={fieldState.invalid}>
        <FieldLabel htmlFor={field.name}>{t("[feature].form.email")}</FieldLabel>
        <Input {...field} id={field.name} type="email" aria-invalid={fieldState.invalid} />
        <FieldDescription>{t("[feature].form.emailHint")}</FieldDescription>
        {fieldState.error?.message && <FieldError>{t(fieldState.error.message)}</FieldError>}
      </Field>
    )}
  />
</FieldGroup>
```

- `data-invalid` on `Field` styles the label and the control; `aria-invalid` on the control tells a screen reader the value is rejected. Both come from `fieldState.invalid`.
- `FieldDescription` is help text and stays visible; `FieldError` is the error and renders only when there is one. The message is a translation key, so it goes through `t()` as `FieldError`'s children; `t` never receives `undefined`.
- A control that does not take `{...field}` as is (a `Select`, a `Checkbox`) maps it: `value={field.value} onValueChange={field.onChange}`, `checked={field.value} onCheckedChange={field.onChange}`.
- A raw `div` with a label and a `span`, or the legacy `Form`/`FormField`/`FormItem`, is never the layout. Visual layout beyond `Field` is `ui-conventions`; this skill owns the field's wiring.
- The resolver is the only validation; no manual `onChange` checks.

## Submit

- The submit target is a mutation hook from the module's mutations file.
- The button takes `disabled={isSubmitting || mutation.isPending}` and a `Spinner` with `data-icon="inline-start"`, and keeps its label rather than swapping it.
- `isSubmitting` is accurate only when `handleSubmit`'s callback awaits or returns the mutation's promise; [lifecycle.md](lifecycle.md) shows both shapes.

## Multi-step

Step components share the one form through `FormProvider`; each step reads it with `useFormContext` and renders its fields through `Controller` the same way.

## No React 19 form action on an RHF form

`<form action={...}>`/`useActionState` and `handleSubmit` are two handlers for the same submit event. Whichever React invokes first wins, in practice the action, so `zodResolver` never runs and invalid values reach `mutationFn`. `useFormStatus().pending` reads a status this form never sets, since the submit path RHF uses never calls the mechanism `useFormStatus` watches; `formState.isSubmitting` is the real flag, already in scope. This holds for one-field forms too; there is no size below which a second form pattern is worth it.

## Versions

Check `package.json` once in the session.

- Zod 3 against Zod 4: the table in [schemas.md](schemas.md).
- React Hook Form: 7.x is stable; 8.0 is in beta and makes the methods `useForm` returns keep their reference, for the React Compiler. Until then `form.watch()` is the API the Compiler cannot track (`react` skill, APIs the Compiler skips), which is one more reason for `useWatch`.
