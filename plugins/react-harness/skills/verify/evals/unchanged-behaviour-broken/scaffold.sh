#!/usr/bin/env bash
# A change on top of a working module. The new criteria are met; two things the spec's
# Unchanged behaviour protects are broken on the way: the signed-out guard is removed from
# the form, and the list is sliced before it is sorted, so the order across pages is lost.
set -eu

git init -q -b main .
git config user.email fixture@example.com
git config user.name fixture

cat > package.json <<'EOF'
{ "name": "fixture", "private": true, "type": "module", "scripts": { "test": "node --test" } }
EOF

mkdir -p src/features/comments/model src/features/comments/ui src/shared/session .planning/comment-pagination

cat > src/shared/session/index.ts <<'EOF'
export interface SessionUser {
  id: string
}

export declare const useSession: () => { user: SessionUser | null }
EOF

cat > src/features/comments/model/types.ts <<'EOF'
export interface Comment {
  id: string
  text: string
  author: { id: string; name: string }
  createdAt: string
}
EOF

cat > src/features/comments/model/sort-comments.js <<'EOF'
export const sortComments = (comments) => {
  return [...comments].sort((a, b) => a.createdAt.localeCompare(b.createdAt))
}
EOF

cat > src/features/comments/model/sort-comments.test.js <<'EOF'
import assert from "node:assert/strict"
import { test } from "node:test"
import { sortComments } from "./sort-comments.js"

test("sorts oldest first", () => {
  const sorted = sortComments([
    { id: "b", createdAt: "2026-02-01T00:00:00Z" },
    { id: "a", createdAt: "2026-01-01T00:00:00Z" },
  ])
  assert.deepEqual(
    sorted.map((comment) => comment.id),
    ["a", "b"],
  )
})
EOF

cat > src/features/comments/ui/comment-list.tsx <<'EOF'
import { sortComments } from "../model/sort-comments.js"
import type { Comment } from "../model/types"

interface CommentListProps {
  comments: Comment[]
}

export const CommentList = ({ comments }: CommentListProps) => {
  return (
    <ul className="flex flex-col gap-3">
      {sortComments(comments).map((comment) => (
        <li key={comment.id}>
          <span className="font-medium">{comment.author.name}</span>
          <p>{comment.text}</p>
        </li>
      ))}
    </ul>
  )
}
EOF

cat > src/features/comments/ui/comment-form.tsx <<'EOF'
import { useState } from "react"
import { useTranslation } from "react-i18next"
import { useSession } from "../../../shared/session"

interface CommentFormProps {
  isPending: boolean
  onSubmit: (text: string) => void
}

export const CommentForm = ({ isPending, onSubmit }: CommentFormProps) => {
  const { t } = useTranslation("comments")
  const { user } = useSession()
  const [text, setText] = useState("")

  if (!user) {
    return null
  }

  return (
    <form
      className="flex w-full gap-2"
      onSubmit={(event) => {
        event.preventDefault()
        onSubmit(text)
      }}
    >
      <textarea
        className="min-w-0 flex-1"
        value={text}
        onChange={(event) => {
          setText(event.target.value)
        }}
      />
      <button type="submit" disabled={isPending}>
        {t("submit")}
      </button>
    </form>
  )
}
EOF

cat > .planning/comment-pagination/SPEC.md <<'EOF'
# SPEC: comment-pagination
**Shape:** change

## Request
change: the comment list paginates, 20 per page

## Goal
A reader sees the first 20 comments and loads more on demand.

## Behaviour
R-1 WHEN the article page opens THE UI SHALL show the first 20 comments
R-2 WHEN the reader presses "Load more" THE UI SHALL append the next 20 comments
R-3 WHILE every comment is shown THE UI SHALL hide "Load more"

## Unchanged behaviour
- Comments are shown oldest first, across the whole list.
- A signed-out reader sees no comment form.
- The submit button is disabled while a comment is being sent.

## Data sources
none; the list is already loaded by the page.

## Acceptance criteria
AC-1 The list shows 20 comments when the page opens (R-1)
AC-2 Pressing "Load more" appends the next 20 comments (R-2)
AC-3 "Load more" is hidden once every comment is shown (R-3)

## Out of scope
Server-side pagination.

## Assumptions

## Open questions
EOF

cat > .planning/comment-pagination/PLAN.md <<'EOF'
# PLAN: comment-pagination

**Spec:** `.planning/comment-pagination/SPEC.md` — authoritative for behaviour and acceptance criteria.

## Modules
| # | Path | Role | Depends on | Serves |
|---|---|---|---|---|
| 1 | src/features/comments | page slicing, "Load more" in the list | — | AC-1, AC-2, AC-3 |

## Contract
none

## Decisions
Pagination is client-side: the page keeps the full list and the component shows a growing slice.

## Coverage
| AC | Modules | Evidence `verify` should expect |
|---|---|---|
| AC-1 | 1 | executed: the paginate test |
| AC-2 | 1 | executed: the paginate test; static: the button's handler |
| AC-3 | 1 | static: the condition around the button |
EOF

git add -A
git commit -q -m "base: comments module and the pagination plan"

cat > src/features/comments/model/paginate.js <<'EOF'
export const PAGE_SIZE = 20

export const paginate = ({ items, page }) => {
  return items.slice(0, page * PAGE_SIZE)
}
EOF

cat > src/features/comments/model/paginate.test.js <<'EOF'
import assert from "node:assert/strict"
import { test } from "node:test"
import { paginate } from "./paginate.js"

const items = Array.from({ length: 45 }, (_, index) => ({ id: String(index) }))

test("shows the first 20", () => {
  assert.equal(paginate({ items, page: 1 }).length, 20)
})

test("appends the next 20", () => {
  const visible = paginate({ items, page: 2 })
  assert.equal(visible.length, 40)
  assert.equal(visible[20].id, "20")
})
EOF

cat > src/features/comments/ui/comment-list.tsx <<'EOF'
import { useState } from "react"
import { useTranslation } from "react-i18next"
import { paginate } from "../model/paginate.js"
import { sortComments } from "../model/sort-comments.js"
import type { Comment } from "../model/types"

interface CommentListProps {
  comments: Comment[]
}

export const CommentList = ({ comments }: CommentListProps) => {
  const { t } = useTranslation("comments")
  const [page, setPage] = useState(1)
  const visible = sortComments(paginate({ items: comments, page }))
  const hasMore = visible.length < comments.length

  return (
    <div className="flex flex-col gap-3">
      <ul className="flex flex-col gap-3">
        {visible.map((comment) => (
          <li key={comment.id}>
            <span className="font-medium">{comment.author.name}</span>
            <p>{comment.text}</p>
          </li>
        ))}
      </ul>
      {hasMore ? (
        <button
          type="button"
          onClick={() => {
            setPage(page + 1)
          }}
        >
          {t("loadMore")}
        </button>
      ) : null}
    </div>
  )
}
EOF

cat > src/features/comments/ui/comment-form.tsx <<'EOF'
import { useState } from "react"
import { useTranslation } from "react-i18next"

interface CommentFormProps {
  isPending: boolean
  onSubmit: (text: string) => void
}

export const CommentForm = ({ isPending, onSubmit }: CommentFormProps) => {
  const { t } = useTranslation("comments")
  const [text, setText] = useState("")

  return (
    <form
      className="flex w-full gap-2"
      onSubmit={(event) => {
        event.preventDefault()
        onSubmit(text)
      }}
    >
      <textarea
        className="min-w-0 flex-1"
        value={text}
        onChange={(event) => {
          setText(event.target.value)
        }}
      />
      <button type="submit" disabled={isPending}>
        {t("submit")}
      </button>
    </form>
  )
}
EOF
