# shadcn components instead of custom markup

Answers: which shadcn component replaces the markup I am about to write, how are composite primitives put together, and what changes between a Radix and a Base UI project?

Check what is installed first; a missing component is added with the CLI (`npx shadcn@latest add <name>`, or the project's package runner) and its docs come from `npx shadcn@latest docs <name>`. Most of these arrived in October 2025, so an older project may not have them yet.

## What replaces what

| Instead of | Use |
|---|---|
| a `div` with an icon and "nothing here" text | `Empty` |
| a custom spinning icon or "Loading…" text | `Spinner` |
| a pulsing `div` as a placeholder | `Skeleton` |
| a bordered, coloured callout `div` | `Alert` |
| a styled `span` for a status or count | `Badge` (a status colour is a `Badge` variant or a semantic token) |
| `<hr>` or a `border-t` div | `Separator` |
| an icon or button absolutely positioned over an `Input` | `InputGroup` with `InputGroupAddon` and `InputGroupInput` (or `InputGroupTextarea`) |
| buttons glued together with negative margins | `ButtonGroup`, `ButtonGroupSeparator` for a split button |
| a loop of `Button`s with a manual active state, 2 to 7 options | `ToggleGroup` |
| a flex row with an avatar, text and actions in a list | `Item`, `ItemGroup` |
| keyboard hints in text | `Kbd`, `KbdGroup` |

An icon inside an input, wrong:

```tsx
<div className="relative">
  <SearchIcon className="absolute top-1/2 left-2 size-4 -translate-y-1/2 text-muted-foreground" />
  <Input className="pl-8" placeholder={t("search.placeholder")} />
</div>
```

```tsx
<InputGroup>
  <InputGroupAddon>
    <SearchIcon />
  </InputGroupAddon>
  <InputGroupInput placeholder={t("search.placeholder")} />
</InputGroup>
```

A loading button has no `isLoading` prop: compose `Spinner`, `data-icon` and `disabled`.

```tsx
<Button disabled={isPending}>
  {isPending && <Spinner data-icon="inline-start" />}
  {t("actions.save")}
</Button>
```

## Composite primitives keep their structure

- `Dialog`, `Sheet` and `Drawer` always render `DialogTitle`, `SheetTitle` or `DrawerTitle`; a screen reader announces it. A design with no visible title hides it with `className="sr-only"`.
- Items sit inside their group: `SelectItem` in `SelectGroup`, `DropdownMenuItem` in `DropdownMenuGroup`, `CommandItem` in `CommandGroup`; `TabsTrigger` in `TabsList`, never directly in `Tabs`.
- `Avatar` always has an `AvatarFallback`, for when the image fails.
- `Card` uses `CardHeader`, `CardTitle`, `CardDescription`, `CardContent` and `CardFooter`; everything stuffed into `CardContent` loses the spacing and the semantics.
- An overlay (`Dialog`, `Popover`, `DropdownMenu`, `Tooltip`) manages its own stacking; a manual `z-index` on it fights the portal.

## Radix or Base UI

`components.json` has a `base` field. New shadcn projects default to Base UI since July 2026; Radix stays fully supported and nothing needs migrating.

| | Radix | Base UI |
|---|---|---|
| A custom element as a trigger | `<DialogTrigger asChild><Button /></DialogTrigger>` | `<DialogTrigger render={<Button />} />` |
| Toasts | `sonner`'s `toast()` | shadcn's `toast` component |

Write the form the project's `base` uses; an example in another skill written with `asChild` reads as `render` in a Base UI project.
