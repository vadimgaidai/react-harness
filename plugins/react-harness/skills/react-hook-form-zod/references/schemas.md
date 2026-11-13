# Validation schemas

How is a schema written: its file, its inferred type, its messages, a number field, an env schema, its use with `useForm`, and what differs between Zod 3 and Zod 4?

> Canonical code shape. Replace the placeholders (`[feature]` kebab-case, `[Feature]` PascalCase, `I[Feature]`/`T[Feature]` type identifiers) with real names. The examples are Zod 4.

Placement and filename: the structure skill loaded in this project. A schema is never inline in a component or an API file, wherever the structure skill puts the file: the form, the mutation and the tests import the same schema and its type.

### Defining a schema + inferring the type

```typescript
import { z } from "zod"

export const [feature]Schema = z.object({
  email: z.email("[feature].form.emailInvalid"),
  password: z.string().min(8, "[feature].form.passwordTooShort"),
})

export const [feature]ExtendedSchema = [feature]Schema.extend({
  name: z.string().min(2, "[feature].form.nameTooShort"),
})

export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
export type T[Feature]ExtendedFormValues = z.infer<typeof [feature]ExtendedSchema>
```

A message is a translation key, never text: the field renders `t(error.message)`, so the
schema stays locale-free and the key lives next to the other `[feature]` strings.

### Coercing a number from input

`z.coerce.number()` makes `z.input` for that field `unknown` while `z.output` is `number`:
exactly the divergence the `z.input` equals `z.output` rule forbids on a form schema, because `zodResolver`
types the form against `z.output` while `useForm` defaults and the fields work against
`z.input`. Keep the field a string in the schema and convert in `onSubmit`, where the payload
is built anyway:

```typescript
export const [feature]Schema = z.object({
  quantity: z.string().refine((value) => !Number.isNaN(Number(value)), "[feature].form.quantityInvalid"),
})

export type T[Feature]FormValues = z.infer<typeof [feature]Schema>
```

```typescript
const onSubmit = form.handleSubmit(async (values) => {
  await mutateAsync({ ...values, quantity: Number(values.quantity) })
})
```

`z.input` and `z.output` stay identical (`string`), so `useForm<T[Feature]FormValues>` and
`zodResolver([feature]Schema)` agree, and the numeric payload is built once, at the one place
that already assembles the payload.

### Reference: env validation

Not a form schema, so `.default()` and `.transform()` are fine here: nothing types a form
against it.

```typescript
import { z } from "zod"

const envSchema = z.object({
  MODE: z.enum(["development", "production"]).default("development"),
  VITE_API_URL: z.url(),
  VITE_APP_NAME: z.string().default("React App"),
  VITE_ENABLE_DEVTOOLS: z
    .string()
    .default("false")
    .transform((value) => value === "true"),
})

export type TEnv = z.infer<typeof envSchema>
export { envSchema }
```

### Using a schema with React Hook Form

```tsx
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"

const form = useForm<T[Feature]FormValues>({
  resolver: zodResolver([feature]Schema),
  defaultValues: { email: "", password: "" },
})
```

The schema and its type are imported from where the structure skill puts them.

Rules:

- Always `export type X = z.infer<typeof xSchema>` next to the schema, never a manual duplicate interface.

### Zod 3 against Zod 4

Check `package.json` once in the session. In Zod 4 the chained forms still run but are deprecated; write the Zod 4 column in a Zod 4 project.

| Zod 3 | Zod 4 |
|---|---|
| `z.string().email("key")` | `z.email("key")` |
| `z.string().url()` | `z.url()` |
| `z.string().uuid()` | `z.uuid()` |
| `{ message: "key" }` | `{ error: "key" }`; a plain string argument works in both |
| `invalid_type_error`, `required_error` | one `error` option, a string or a function of the issue |
| `error.format()`, `error.flatten()` | `z.treeifyError(error)` |
| `.strict()`, `.passthrough()` | `z.strictObject({ … })`, `z.looseObject({ … })` |

`@hookform/resolvers` has to be a version that supports the installed Zod major; a resolver
that predates Zod 4 does not type a Zod 4 schema. Read its version beside Zod's.
