---
name: nextjs-frontend
description: Next.js 16 + React 19 + Tailwind CSS 4 frontend development. App Router, Server Components, Server Actions, shadcn/ui, responsive design, SaaS dashboards.
---

# Next.js Frontend Skill

## When to Activate
- Building web frontends with Next.js
- Creating SaaS dashboards
- Working with React Server Components
- Styling with Tailwind CSS
- Implementing authentication UI, forms, data tables

## Technology Stack (Current Stable)

| Tech | Version | Purpose |
|------|---------|---------|
| Next.js | 16.x | React framework (App Router) |
| React | 19.x | UI library |
| Tailwind CSS | 4.x | Utility-first CSS |
| shadcn/ui | latest | Component library (copy-paste, not dependency) |
| TypeScript | 5.x | Type safety |
| Zod | 3.x | Schema validation |
| TanStack Query | 5.x | Server state management |
| next-auth | 5.x (Auth.js) | Authentication |

## Project Structure (App Router)

```
src/
  app/
    layout.tsx           # Root layout
    page.tsx             # Home page
    globals.css          # Global styles + Tailwind
    (auth)/
      login/page.tsx
      register/page.tsx
    (dashboard)/
      layout.tsx         # Dashboard layout with sidebar
      page.tsx           # Dashboard home
      settings/page.tsx
      analytics/page.tsx
    api/
      auth/[...nextauth]/route.ts
      webhooks/route.ts
  components/
    ui/                  # shadcn/ui components
    layout/
      sidebar.tsx
      header.tsx
      footer.tsx
    forms/
      login-form.tsx
      settings-form.tsx
    data/
      data-table.tsx
      columns.tsx
  lib/
    utils.ts             # cn() helper, formatters
    api-client.ts        # API fetch wrapper
    validators.ts        # Zod schemas
  hooks/
    use-auth.ts
    use-debounce.ts
  types/
    index.ts
  config/
    site.ts              # Site metadata
    navigation.ts        # Nav items
```

## Core Patterns

### Server Components (default)
```tsx
// app/dashboard/page.tsx - Server Component (no "use client")
import { getAnalytics } from "@/lib/api-client";
import { AnalyticsChart } from "@/components/data/analytics-chart";

export default async function DashboardPage() {
  const data = await getAnalytics();

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      <AnalyticsChart data={data} />
    </div>
  );
}
```

### Client Components (interactive)
```tsx
"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function SearchBar({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState("");

  return (
    <div className="flex gap-2">
      <Input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search..."
        className="max-w-sm"
      />
      <Button onClick={() => onSearch(query)}>Search</Button>
    </div>
  );
}
```

### Server Actions (data mutations)
```tsx
// app/actions/items.ts
"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

const createSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
});

export async function createItem(formData: FormData) {
  const data = createSchema.parse({
    name: formData.get("name"),
    description: formData.get("description"),
  });
  await db.insert(items).values(data);
  revalidatePath("/dashboard/items");
}

// Usage in a Server Component:
// <form action={createItem}>
//   <input name="name" />
//   <button type="submit">Create</button>
// </form>
```

### API Route Handlers
```tsx
// app/api/items/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";

const createSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().optional(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const data = createSchema.parse(body);
    await db.insert(items).values(data);
    return NextResponse.json({ success: true }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: error.errors }, { status: 400 });
    }
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
```

### Metadata API
```tsx
// app/dashboard/layout.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Dashboard",
  description: "App dashboard",
};

// Dynamic metadata per page:
// export async function generateMetadata({ params }): Promise<Metadata> {
//   const item = await getItem(params.id);
//   return { title: item.name };
// }
```

### Loading & Error States
```tsx
// app/dashboard/loading.tsx - shown while Server Component loads
export default function Loading() {
  return <div className="animate-pulse">Loading...</div>;
}

// app/dashboard/error.tsx - catches errors in the segment
"use client";
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

### Dashboard Layout with Sidebar
```tsx
// app/(dashboard)/layout.tsx
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen">
      <Sidebar className="w-64 border-r" />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
```

### Data Fetching with TanStack Query
```tsx
"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

export function useItems() {
  return useQuery({
    queryKey: ["items"],
    queryFn: () => fetch("/api/items").then(r => r.json()),
  });
}

export function useCreateItem() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateItem) =>
      fetch("/api/items", { method: "POST", body: JSON.stringify(data) }).then(r => r.json()),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["items"] }),
  });
}
```

## Tailwind CSS v4 Patterns

**Important**: Tailwind CSS v4 uses CSS-based config instead of `tailwind.config.js`.
```css
/* globals.css - v4 style (replaces @tailwind directives) */
@import "tailwindcss";
```
To migrate from v3: `npx @tailwindcss/upgrade` (requires Node.js 20+).

### Responsive Design
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  {/* Mobile: 1 col, Tablet: 2 cols, Desktop: 4 cols */}
</div>
```

### Dark Mode
```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <h1 className="text-2xl font-bold">Title</h1>
</div>
```

### Design Approach by Project Type
- **SaaS Dashboard**: shadcn/ui + clean layout, data tables, charts (recharts)
- **Landing Page**: bold typography, hero sections, gradients, animations
- **E-commerce**: product grids, filters, cart, checkout flow
- **Admin Panel**: dense layout, lots of data, form-heavy

## When Next.js vs Other

| Use Case | Framework | Why |
|----------|-----------|-----|
| SSR/SSG with React | **Next.js** | Full-stack React, Server Components, built-in routing |
| SPA dashboard (no SEO) | **Vite + React** | Lighter, faster builds, no SSR overhead |
| Content-heavy / blog | **Astro** | Ships zero JS by default, any component framework |
| Full-stack Ruby | **Ruby on Rails** + Hotwire | See `ruby-on-rails` skill |
| Vue.js ecosystem | **Nuxt.js** | Equivalent to Next.js for Vue |
| Minimal bundle, perf | **SvelteKit** | Compiler-based, smallest runtime |
| Static docs / marketing | **Astro** | Static-first, partial hydration |
| Simple multi-page | Rails or Django templates | Server-rendered, no JS framework needed |

## State Management Decision

| Complexity | Solution | When to Use |
|------------|----------|-------------|
| Server state (API data) | **TanStack Query 5** | Caching, revalidation, pagination — already in stack |
| Simple global state | **Zustand** | Tiny (~1KB), hooks-based, zero boilerplate |
| Atomic state | **Jotai** | Bottom-up approach, great for independent state pieces |
| Complex state machines | **XState** | Finite state machines for multi-step flows |
| Large apps / teams | **Redux Toolkit** | Standard for large codebases, strong devtools |
| Form state | **React Hook Form** + Zod | Performant forms with schema validation (Zod already in stack) |
| URL state | **nuqs** | Type-safe search params, shareable state |

Default recommendation: TanStack Query for server state + Zustand for client state.

## Animation Libraries

| Library | Best For | Bundle |
|---------|----------|--------|
| **Framer Motion** | React animations, gestures, layout transitions | ~30KB |
| **GSAP** | Complex timelines, scroll-driven, SVG morphing | ~25KB |
| **Motion One** | Lightweight alternative to Framer Motion | ~3KB |
| CSS transitions | Simple hover/focus/appear effects | 0KB |

Default recommendation: CSS transitions for simple effects, Framer Motion for complex interactions.

## CSS Framework Comparison

| Framework | Approach | When to Use |
|-----------|----------|-------------|
| **Tailwind CSS 4** | Utility-first | Default choice (in stack) |
| **CSS Modules** | Scoped CSS files | When Tailwind feels too verbose for complex layouts |
| **Vanilla Extract** | Zero-runtime CSS-in-TS | Type-safe styling with no runtime cost |
| **Panda CSS** | Utility + type-safe | Tailwind alternative with better TypeScript integration |

Default recommendation: Tailwind CSS 4 for all projects.
