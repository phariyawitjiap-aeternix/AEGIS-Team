# Human Input -- AEGIS Web Dashboard + Pixel Office

> Collected: 2026-03-30 | Spec: DASH-001

## Answers

### 1. Deployment Strategy
- **Primary:** localhost (npm run dev)
- **Remote:** Docker container + Vercel deployment
- Both targets must be supported from day one

### 2. Data Source
- Read `_aegis-brain/` files via Next.js API routes
- Polling `heartbeat.log` every 2 seconds for Mother Brain status
- All data is read-only (dashboard never writes to _aegis-brain/)

### 3. Visual Style
- Pixel-art animated sprites for all 13 agents
- Each agent has unique color palette and accessories matching their emoji
- Retro office aesthetic with modern UI chrome

### 4. Technology Stack
- Next.js 15 (App Router)
- React 19
- Tailwind CSS v4
- HTML5 Canvas (Pixel Office rendering)

### 5. Feature Priority
- Dashboard + Pixel Office ship together as a single feature
- They are two views of the same data, not separate products
