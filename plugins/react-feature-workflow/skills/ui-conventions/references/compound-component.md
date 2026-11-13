# Compound Component Pattern

Answers: a component has two or more related parts; what is the `.Root` contract, when does it need shared state and context, and how do controlled and uncontrolled use work?

> Canonical code shape. Replace the placeholders (`[name]` kebab-case, `[Name]` PascalCase, `I[Name]` type identifiers) with real names, and the `@/components/ui/` import paths with the project's own primitives alias.

When a component has 2+ related nested parts, export an object with `.Root` and named parts.
Shared state is not a condition of the pattern: a `Card` with a header, content and footer
is a compound component with no state at all. If the parts do need shared state, `.Root`
owns it and the parts read it through context — context is added only when state or an
action has to reach a part, never to make a component look like the pattern.

### Composition without shared state

In `[name]/[name].tsx`:

```tsx
import type { ComponentProps } from "react"

import { cn } from "@/lib/utils"

const [Name]Root = ({ className, ...rest }: ComponentProps<"section">) => {
  return <section className={cn("rounded-lg border bg-card text-card-foreground", className)} {...rest} />
}

const [Name]Header = ({ className, ...rest }: ComponentProps<"header">) => {
  return <header className={cn("flex flex-col gap-1 p-6", className)} {...rest} />
}

const [Name]Content = ({ className, ...rest }: ComponentProps<"div">) => {
  return <div className={cn("p-6 pt-0", className)} {...rest} />
}

const [Name]Footer = ({ className, ...rest }: ComponentProps<"footer">) => {
  return <footer className={cn("flex items-center p-6 pt-0", className)} {...rest} />
}

export const [Name] = {
  Root: [Name]Root,
  Header: [Name]Header,
  Content: [Name]Content,
  Footer: [Name]Footer,
}
```

```tsx
<[Name].Root>
  <[Name].Header>{t("[name].title")}</[Name].Header>
  <[Name].Content>{children}</[Name].Content>
  <[Name].Footer>
    <Button>{t("actions.save")}</Button>
  </[Name].Footer>
</[Name].Root>
```

Nothing here is shared, so nothing is lifted: no Provider, no context hook, no state in `Root`
that no behaviour needs. A part may still hold local state of its own (a `Footer` tracking
whether its menu is open) even though nothing else reads it.

### Composition with shared state

In `[name]/[name].tsx`:

```tsx
import {
  createContext,
  useContext,
  useState,
  type ComponentProps,
  type ReactNode,
} from "react"

interface I[Name]Context {
  isOpen: boolean
  toggle: () => void
}

const [Name]Context = createContext<I[Name]Context | null>(null)

const use[Name]Context = () => {
  const context = useContext([Name]Context)
  if (!context) {
    throw new Error("[Name].Trigger and [Name].Content must be rendered inside [Name].Root")
  }
  return context
}

interface I[Name]RootProps {
  children: ReactNode
  open?: boolean
  defaultOpen?: boolean
  onOpenChange?: (open: boolean) => void
}

const [Name]Root = ({ children, open, defaultOpen = false, onOpenChange }: I[Name]RootProps) => {
  const [uncontrolledOpen, setUncontrolledOpen] = useState(defaultOpen)
  const isControlled = open !== undefined
  const isOpen = isControlled ? open : uncontrolledOpen

  const toggle = () => {
    const next = !isOpen
    if (!isControlled) {
      setUncontrolledOpen(next)
    }
    onOpenChange?.(next)
  }

  return <[Name]Context value={{ isOpen, toggle }}>{children}</[Name]Context>
}

const [Name]Trigger = ({ onClick, ...rest }: Omit<ComponentProps<"button">, "aria-expanded">) => {
  const { isOpen, toggle } = use[Name]Context()

  return (
    <button
      type="button"
      {...rest}
      aria-expanded={isOpen}
      onClick={(event) => {
        onClick?.(event)
        if (event.defaultPrevented) {
          return
        }
        toggle()
      }}
    />
  )
}

const [Name]Content = (props: Omit<ComponentProps<"div">, "hidden">) => {
  const { isOpen } = use[Name]Context()

  return <div {...props} hidden={!isOpen} />
}

export const [Name] = {
  Root: [Name]Root,
  Trigger: [Name]Trigger,
  Content: [Name]Content,
}
```

Uncontrolled — `[Name]` owns the open state:

```tsx
<[Name].Root defaultOpen>
  <[Name].Trigger>{t("[name].toggle")}</[Name].Trigger>
  <[Name].Content>{children}</[Name].Content>
</[Name].Root>
```

Controlled — the parent owns it, and `[Name]` never also writes `uncontrolledOpen`:

```tsx
<[Name].Root open={isOpen} onOpenChange={setIsOpen}>
  <[Name].Trigger>{t("[name].toggle")}</[Name].Trigger>
  <[Name].Content>{children}</[Name].Content>
</[Name].Root>
```

### What each part of the contract looks like here

- **`Root` owns whatever is shared** — `isOpen` and `toggle` live in `[Name]Root`, nowhere
  else; in the stateless `Card` there is nothing to own, and `Root` owns nothing.
- **A part never keeps a competing copy** — `[Name]Trigger` and `[Name]Content` read `isOpen`
  from context and call `toggle()`; neither declares its own `useState` for it. Local state
  that duplicates nothing shared is not a copy.
- **A context-reading part outside its `Root` throws, naming the `Root` it needs** —
  `use[Name]Context` refuses silently-wrong behaviour (a `Content` that renders as if always
  closed) in favour of an error that names the fix. A stateless part has no such requirement.
- **Controlled and uncontrolled never both drive the state** — `open !== undefined` decides
  which one the `isOpen` getter and the `toggle` setter use for the whole lifetime of this
  render; `toggle` only writes `uncontrolledOpen` when the parent isn't already driving `open`.
- **One source of truth for what `Root` controls** — `hidden` on `Content` and
  `aria-expanded` on `Trigger` are derived from `isOpen`, set after the spread so a caller
  cannot pass `hidden={false}` and show content the trigger reports as collapsed, and omitted
  from the parts' prop types so the compiler says so too.
- **A wrapper around a primitive forwards events, `ref` and the props the primitive expects**
  — every part above is `ComponentProps<...>` plus `...rest`. `[Name]Trigger` calls the
  caller's `onClick` first and skips its own `toggle()` when that handler called
  `event.preventDefault()`, so the caller can cancel the action without losing it.
- **Composition over a primitive keeps focus and keyboard handling** — building this on top of
  a shadcn primitive (a `Popover`, a `Collapsible`) means wrapping `PopoverTrigger`/
  `PopoverContent` the same way: forward `...rest` through to the primitive so its own
  `onKeyDown`, focus trap and roving tabindex still run; a wrapper that intercepts `onKeyDown`
  without calling the primitive's own handler breaks keyboard use silently.
- **A new part is added for a scenario that exists** — a `[Name].Footer` is worth adding when
  a real caller needs a footer slot, not to mirror `Header` for symmetry.
- **Public exports follow the loaded structure skill** — which file exports `[Name]` and how a
  caller imports it is that skill's decision.

Rules:

- 2+ related nested parts → this pattern, with or without shared state.
- Always expose `.Root` as the wrapper. Shared state, when there is any, lives in `Root` and
  reaches the parts through context; a context-reading part rendered outside `Root` throws.
- No state, Provider or Context added for the pattern's sake, with no behaviour that needs
  it. A part's own local state is allowed even when nothing else reads it.
- Internal helpers that are not part of the public surface stay as separate files in the module, not on the compound object.
- Placement, including why it never lands in the shadcn-managed primitives folder: the structure skill loaded in this project.
