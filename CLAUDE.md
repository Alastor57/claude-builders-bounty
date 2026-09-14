# CLAUDE.md — Project Guidance for Claude Code

> **Bounty #2** — Create an opinionated CLAUDE.md for a typical SaaS project.

## Stack & Versions
- **Runtime**: Node.js 20+, Python 3.11+
- **Framework**: Next.js 15 App Router
- **Database**: SQLite via `better-sqlite3` (or Turso for managed)
- **Auth**: NextAuth.js v5
- **Testing**: Vitest + Playwright

## Folder Structure
```
├── src/
│   ├── app/              # Next.js App Router pages
│   │   ├── (auth)/       # Login, register, forgot-password
│   │   ├── dashboard/    # Main app (protected)
│   │   └── api/          # REST and tRPC routes
│   ├── components/       # Shared + feature-scoped UI
│   │   ├── ui/           # Primitive components (shadcn/ui base)
│   │   └── features/     # Feature modules (auth, billing, teams)
│   ├── lib/              # Utilities, helpers, shared types
│   │   ├── db.ts         # Database connection singleton
│   │   ├── auth.ts       # Auth helpers
│   │   └── utils.ts      # cn(), formatters, validators
│   ├── services/         # External integrations (Stripe, email, etc.)
│   └── types/            # Shared TypeScript types
├── prisma/
│   ├── schema.prisma     # Single source of truth for DB schema
│   └── migrations/
├── scripts/              # Build, deploy, seed scripts
├── tests/                # E2E + integration tests
├── docs/                 # ADRs, runbooks
├── .github/workflows/    # CI/CD
├── package.json
├── vitest.config.ts
└── CLAUDE.md             # This file
```

## Database Migration Rules
- **Never edit schema.prisma by hand** — always use `npx prisma migrate dev`
- Migration files are immutable once pushed — fix with a new migration, not edits
- Every migration must have a corresponding `down` (rollback) step
- Run `npx prisma migrate deploy` in CI before `npm run build`
- Add indexes via `@@index` directives in Prisma schema, not raw SQL

## Development Commands
| Command | Purpose |
|---------|---------|
| `npm run dev` | Start dev server (Turbo) |
| `npm run build` | Production build (checks DB + types) |
| `npm run test` | Unit tests (Vitest) |
| `npm run test:e2e` | E2E tests (Playwright) |
| `npm run lint` | ESLint + Prettier check |
| `npx prisma migrate dev` | Create migration |
| `npx prisma studio` | DB GUI |

## Code Patterns

### API Routes
- Use Route Handlers (`app/api/**/route.ts`) for REST
- Validate input with Zod before processing
- Return consistent shape: `{ success: boolean, data?: T, error?: { code, message } }`
- Never expose raw error messages to clients

### Components
- Feature-scoped components live in `src/components/features/<feature>/`
- Shared primitives in `src/components/ui/` (from shadcn/ui)
- Use `"use client"` only when necessary (hooks, browser APIs)
- Keep Server Components as default

### Database Access
- All DB queries go through `src/lib/db.ts` singleton
- Use Prisma's typed queries; avoid `$queryRaw` unless absolutely necessary
- Wrap multi-write operations in `$transaction`
- Paginate with `skip/take` or cursor pagination; never use `findMany` without limit

## What We Don't Do (and Why)
- **No Redux/Zustand** — Server Components + Next.js Query reduce need for client state
- **No GraphQL** — REST Route Handlers + tRPC give us type safety without the complexity
- **No raw SQL in application code** — Prisma schema is the abstraction layer
- **No monolithic utils file** — Split by domain (`date.ts`, `string.ts`, `money.ts`)
- **No `any`** — Strict `noImplicitAny` in tsconfig; use proper types or `unknown` with guards

## Testing Strategy
- Unit tests: `*.test.ts` next to source files (Vitest)
- Integration tests: `tests/integration/` (real DB, spun up/down per suite)
- E2E: `tests/e2e/` (Playwright, dev server auto-started)
- Aim for 80%+ coverage on business logic; don't chase 100% on plumbing

## Configuration
- Environment variables in `.env.local` (gitignored) — see `.env.example` for required keys
- Never commit secrets, tokens, or `.env` files
- Use `process.env` with explicit casting and validation (Zod `envSchema`)

## Linting & Formatting
- ESLint flat config (`eslint.config.js`) — runs in CI
- Prettier for formatting — run `npm run format` before committing
- Husky pre-commit hook auto-runs lint + test
