# Extending Base Components

Answers: how does a component built on a shadcn primitive take and forward the primitive's props?

> Canonical code shape. Replace the placeholders (`[name]` kebab-case, `[Name]` PascalCase, `I[Name]` type identifiers) with real names, and the `@/components/ui/` import paths with the project's own primitives alias.

When you build on top of a shadcn (or any base) component, **inherit its props** rather than redeclaring HTML attributes or variants.

### shadcn `Button` — the base

Its signature (`components/ui/button.tsx`), body omitted — it is shadcn's own, never hand-edited:

```tsx
function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean
  })
```

### A domain-specific wrapper (`SubmitButton`)

In `[feature]/submit-button.tsx`:

```tsx
import type { ComponentProps } from "react"

import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"

interface ISubmitButtonProps extends ComponentProps<typeof Button> {
  isPending?: boolean
}

export const SubmitButton = ({
  isPending,
  disabled,
  className,
  children,
  ...rest
}: ISubmitButtonProps) => {
  return (
    <Button
      type="submit"
      disabled={disabled || isPending}
      className={cn("relative", className)}
      {...rest}
    >
      {isPending && <Spinner data-icon="inline-start" />}
      {children}
    </Button>
  )
}
```

What this gets us for free:

- All HTML `<button>` attributes (`onClick`, `aria-*`, `data-*`, `form`, `name`, `value`, …)
- All shadcn variants (`variant`, `size`, `asChild`) via `VariantProps`
- `className` merging via `cn()`, imported from wherever the project's own components take it (`@/lib/utils`, or the `cn` package shadcn uses since September 2026)
- `disabled` and `className` are taken out of the props before the spread, so the wrapper's own values win; anything else the caller passes, `type` included, reaches `Button` through `...rest` and overrides the wrapper's default

Rules:

- Use `ComponentProps<typeof Button>`, never copy-paste props.
- Forward `...rest` to the base component.
- Don't re-declare variant props — re-export base variants if a consumer needs them.
- Placement: the structure skill loaded in this project.

### An input with a leading icon

Not a wrapper with an absolutely positioned icon: `InputGroup` owns that layout ([components.md](components.md)). A domain component composes it:

In `[feature]/search-input.tsx`:

```tsx
import type { ComponentProps } from "react"
import { SearchIcon } from "lucide-react"

import { InputGroup, InputGroupAddon, InputGroupInput } from "@/components/ui/input-group"

export const SearchInput = (props: ComponentProps<typeof InputGroupInput>) => {
  return (
    <InputGroup>
      <InputGroupAddon>
        <SearchIcon />
      </InputGroupAddon>
      <InputGroupInput {...props} />
    </InputGroup>
  )
}
```
