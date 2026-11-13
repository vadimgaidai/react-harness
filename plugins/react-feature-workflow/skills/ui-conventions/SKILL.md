---
name: ui-conventions
description: shadcn/ui + Tailwind conventions for any React component or .tsx that renders UI — semantic color tokens instead of raw colors, size-* instead of h-* w-*, gap-* instead of space-*, no dark-variant overrides, scale classes that exist in the project's @theme, icons from components.json's iconLibrary, Empty/Spinner/Skeleton/InputGroup and other shadcn components instead of custom markup, Radix asChild or Base UI render, wrapping a primitive from components/ui via ComponentProps, compound components with .Root, accessible names, t() for visible text. Use when writing, fixing or reviewing a component, a className, a Button, Dialog, Card, Input or other shadcn primitive, an icon, or a layout.
---

# shadcn/ui + Tailwind

- Use the installed primitive (`components/ui/[name]` or wherever `components.json` puts it, imported by module, not barrel); if it is missing, find it with the `shadcn` MCP server and add it with the CLI; never hand-roll one or copy its source to tweak a style.
- Read `base` in `components.json` once: a Radix project composes a custom trigger with `asChild` and toasts with `sonner`, a Base UI project with `render` and shadcn's own `toast`.
- A shadcn component replaces custom markup wherever one exists: `Empty`, `Spinner`, `Skeleton`, `Alert`, `Badge`, `Separator`, `InputGroup`, `ButtonGroup`, `ToggleGroup`, `Item` ([references/components.md](references/components.md)).
- A composite primitive keeps its full structure: `Dialog`, `Sheet` and `Drawer` always have a title (`sr-only` when hidden), items sit in their group (`SelectItem` in `SelectGroup`, `TabsTrigger` in `TabsList`), `Avatar` has an `AvatarFallback`, `Card` uses its header, title, description, content and footer.
- A wrapper extends `ComponentProps<typeof X>` and forwards `...rest`; it never re-declares the primitive's props or variants.
- Two or more related nested parts are a compound component with `.Root`; `.Root` owns shared state, context exists only when state or an action must reach a part, and a context-reading part outside `.Root` throws a named error.
- A component types its props on the parameter, `export const X = ({ … }: IXProps) => …`, as React 19 does, never `FC<IXProps>`; one exported component per file, props as an `I[Name]Props` interface, or the primitive's `ComponentProps<typeof X>` directly when the wrapper adds no prop of its own. Form layout is `Field`/`FieldGroup` from the `react-hook-form-zod` skill.
- Semantic tokens only (`bg-background`, `text-muted-foreground`, `border-border`), never a raw hex or palette color, so both themes come from one token set.
- No `dark:` in a component; a wrong dark look is a token fix (the `theme-sync` agent).
- Horizontal sides are logical, so a right-to-left language mirrors the layout without a second set of classes: `ms-*`/`me-*`, `ps-*`/`pe-*`, `text-start`/`text-end`, `border-s`/`rounded-s-*`, never `ml`/`mr`/`pl`/`pr`/`left`/`right`; a directional icon (arrow, chevron) flips with `rtl:rotate-180`.
- `size-*` when width equals height; `gap-*`, not `space-x/y-*`; `truncate`, not its three classes.
- Conditional classes go through `cn()`, never a template string with a ternary; no manual `z-index` on an overlay.
- A scale class must exist in the project's `@theme` or `tailwind.config`, since a reset namespace keeps only the keys it lists and the rest emit no CSS.
- No bracket value (`w-[327px]`) where a scale owns the property; with no matching token, use the nearest one or ask the user.
- `className` on an exported component positions it (margin, grid placement) and nothing else.
- Icons come from the `iconLibrary` in `components.json` (`lucide-react` here); inside a `Button` they take `data-icon="inline-start"`/`"inline-end"` and no size; a standalone icon takes `size-*` and, when it carries meaning, a label; a prop takes the icon component (`icon={CheckIcon}`), not a string key.
- Every visible string, including toasts, schema messages, fallbacks and formatted numbers, dates and plurals, goes through `t("key")` and the project's i18n formatting.
- Loading, empty and error each render something of their own (under a suspense read the `QueryBoundary`'s skeleton and error fallbacks, and the component's own empty branch); split JSX past ~80 lines or a chunk with its own state; one file fetches, maps or renders.
- Where a file lives is the structure skill loaded in this project; with none loaded, no `index` barrel and no folder per component: one file per component next to its caller.

## Example

Width equals height, a palette color, a space utility:

```tsx
<p className="flex items-center space-x-2 text-gray-500">
  <RefreshCw className="h-4 w-4 animate-spin" />
  {t("sync.inProgress")}
</p>
```

```tsx
<p className="flex items-center gap-2 text-muted-foreground">
  <RefreshCw className="size-4 animate-spin" />
  {t("sync.inProgress")}
</p>
```

## References

- [references/components.md](references/components.md): before writing a styled `div`, `span` or `hr`, a loading or empty state, an icon or button inside an input, a set of toggle buttons, a custom trigger, or a toast.
- [references/styling.md](references/styling.md): before the first scale class from a namespace (theme resets in v3 and v4), when a design value has no token, for logical (right-to-left safe) classes, and for the icon and component-shape rules.
- [references/extending-components.md](references/extending-components.md): when wrapping a shadcn primitive in a domain component.
- [references/compound-component.md](references/compound-component.md): when a component has two or more parts, and always before adding context, controlled/uncontrolled props or a new part to one.
- [references/reviewing.md](references/reviewing.md): the questions `review` asks; not needed when writing code.
