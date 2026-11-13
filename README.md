# AIRO XPRESS

AIRO XPRESS is a Bangladesh-focused marketplace application built with Next.js App Router, TypeScript, PostgreSQL, Prisma, and a responsive custom storefront. It includes a real relational schema, migrations, database-backed customer sessions, catalog/search APIs, cart and stock-aware order creation, protected admin tools, seller applications, delivery-zone configuration, and an explicitly fail-closed payment boundary.

> **Deployment status:** This is a working marketplace foundation, not a claim that every external or operational integration is already production-enabled. Digital payment adapters, SMS/phone verification, refunds/returns processing, delivery-personnel operations, and vendor payouts require provider/business configuration and additional workflow implementation. bKash, Nagad, and card orders are rejected until real provider adapters are implemented; no payment is simulated. See [Known gaps](#known-gaps-before-a-full-production-launch).

## Requirements

- Node.js 20.9 or newer (Node 22 LTS recommended)
- npm
- PostgreSQL 14 or newer
- A Resend account/API key for email verification and password-reset delivery (optional in local development)
- Cloudinary account credentials for product image uploads (optional)

## Project structure

```text
app/          Next.js pages, metadata routes, and API route handlers
components/   Storefront, authentication, and shared UI
lib/          Authentication, database, checkout, email, and API helpers
prisma/       PostgreSQL schema, migrations, and seed script
public/       Static brand assets and Bangladesh location data
tests/        Focused automated tests
```

The main runtime dependencies are Next.js 15, React 19, TypeScript, Prisma 6, PostgreSQL, and Zod. Cloudflare deployments additionally use OpenNext and the Neon Prisma adapter.

## Install and run locally

1. Copy `.env.example` to `.env` and set pooled `DATABASE_URL`, direct `DIRECT_URL`, and `APP_URL` (`http://localhost:3000` for local development; the canonical HTTPS origin in production). Do not commit `.env`.
2. Create an empty PostgreSQL database named `airo_xpress` (or update `DATABASE_URL`).
3. Install and initialize:

   ```sh
   npm ci
   npm run db:generate
   npm run db:deploy
   npm run db:seed
   npm run dev
   ```

4. Visit `http://localhost:3000`.

The seed creates marketplace categories and the default delivery tiers: Inside Dhaka (BDT 70), Suburban Dhaka (BDT 100), and Outside Dhaka (BDT 120). These fees can be changed or disabled in the admin dashboard. It does **not** create sample products. To create the first administrator, set both `ADMIN_EMAIL` and `ADMIN_PASSWORD` before running the seed. The seed requires an administrator password with at least 14 characters and hashes it with bcrypt. Do not use shared/default credentials.

For iterative schema development use `npm run db:migrate` instead of `db:deploy`. Docker builds pass the canonical `APP_URL` as a build argument for static metadata and use non-production database URL placeholders only during build; Compose supplies the internal PostgreSQL URLs at runtime and for migrations.

## Environment configuration

| Variable | Required | Purpose |
|---|---:|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string used by Prisma |
| `DIRECT_URL` | Yes for Prisma CLI/migrations | Direct, non-pooled PostgreSQL URL; Prisma 6.19 uses it for migration commands while the application runtime uses `DATABASE_URL` |
| `APP_URL` | Yes in production | Canonical public URL; used for email links, metadata and sitemap |
| `NEXT_PUBLIC_META_PIXEL_ID` | Optional | Numeric Meta Pixel ID; public and safe to expose in browser code |
| `META_CAPI_ACCESS_TOKEN` | Optional | Server-only Meta Conversions API access token; never expose it with a `NEXT_PUBLIC_` prefix |
| `META_CAPI_GRAPH_API_VERSION` | For CAPI | Graph API version currently supported by Meta for your account, in `vX.Y` format |
| `META_CAPI_TEST_EVENT_CODE` | Optional | Meta Events Manager test code; events remain unverified until received there |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | To bootstrap admin | Seed-time administrator account; keep the password out of source control |
| `RESEND_API_KEY`, `EMAIL_FROM` | For email flows | Registration verification and password-reset links |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | For uploads | Server-signed image uploads; API secret is server-only |
| `BKASH_APP_KEY`, `BKASH_APP_SECRET`, `BKASH_USERNAME`, `BKASH_PASSWORD` | Not sufficient alone | Required merchant credentials for a future bKash adapter |
| `NAGAD_MERCHANT_ID`, `NAGAD_MERCHANT_PRIVATE_KEY` | Not sufficient alone | Required merchant credentials for a future Nagad adapter |
| `SSL_COMMERZ_STORE_ID`, `SSL_COMMERZ_STORE_PASSWORD` | Not sufficient alone | Required merchant credentials for a future card/SSLCommerz adapter |

Never expose provider secrets with a `NEXT_PUBLIC_` prefix.

## Features implemented

- Responsive branded storefront, category navigation, product search, category/price query filters, sorting, review display, SEO metadata, product JSON-LD, `robots.txt`, and database-backed sitemap. Each active product has a stable `/product/{slug}` URL with canonical and Open Graph product metadata; an uploaded publicly accessible product image is needed for an image sharing preview.
- Optional Meta Pixel browser events: `PageView`, `ViewContent`, `AddToCart`, `InitiateCheckout`, and `Purchase`. Password-reset and email-verification pages do not load or send page-view events, and their one-time tokens are removed from the address bar. Purchase fires only after the server successfully saves an order; for COD it means an order was placed, not that payment was collected.
- Optional server-side Meta Conversions API `Purchase` event after the order transaction commits. The event uses the same stable `event_id` as the browser event for deduplication, hashes normalized email and phone values, and sends BDT value and item data. Event delivery requires your own Meta dataset/Pixel ID, access token, and currently supported Graph API version. A test event code can route events to Meta Events Manager, but does not itself verify receipt.
- Product-wise guest ordering from ad landing pages with name, Bangladesh phone, district/upazila, address, server-verified delivery fee, COD, stock checks, idempotency, and IP/phone rate limits. Guest orders are managed in Admin but are not attached to a customer account or visible in customer order history.
- Registration, bcrypt password hashing, login/logout, HttpOnly/SameSite sessions stored as SHA-256 token hashes, role checks, rate-limited login/registration/reset requests, email verification, and password reset. Email links require Resend configuration.
- Per-customer database cart with stock checks, saved addresses API, wishlist API, verified-purchase review submission, and order history.
- Bangladesh district/upazila checkout selectors, server-side address validation, tier-based delivery fees, coupon preview and integer-paisa order calculations.
- Transactional order creation with stock decrement, coupon-use limits, delivery fee resolution, address/product snapshots, pending COD payment records, and checkout-request idempotency.
- Admin-only product/image editing, inventory visibility, order details/status updates and customer notifications, customer listing, coupon controls, vendor approval/suspension, delivery fees, sales summaries and CSV order export. Marketing & advertising tools provide product-link/name/price/description copy actions, Meta configuration status, and product-wise order/delivered-sales summaries. Ad creation and campaign budgets remain in Meta Ads Manager.
- Admin-managed product categories and homepage promotions, with banner images stored in Cloudinary rather than the application filesystem.
- Vendor application, admin approval, product creation, and seller-owned price/stock editing. Product ownership is checked server-side.
- Cloudinary upload endpoint with approved-role authorization, image MIME and 5 MB size limits, server-side request signing, and vendor image deletion limited to the stored ID on the vendor-owned image.
- Database-backed newsletter signups with duplicate-safe email normalization and request throttling.
- PostgreSQL schema and initial migration for users, sessions, addresses, catalog, carts, orders, payments, coupons, reviews, wishlists, vendors, shipments, notifications, returns, withdrawals, rate limits, email tokens, and delivery zones.

## Payment behavior

Cash on delivery is the only order method currently accepted. Selecting bKash, Nagad, or card returns a clear unavailable error. `lib/payments.ts` defines the gateway contract and fails closed even when credentials are present until an official provider adapter, signature/callback verification, idempotency, and reconciliation flow have been implemented and tested. Do not enable digital payment options in production until that work is complete and verified with the provider's official sandbox and production credentials.

## API overview

All JSON mutation endpoints validate request bodies with Zod. Authenticated mutations use the HttpOnly session cookie and same-origin checks. Admin and vendor access is enforced on the server for every protected route.

| Method | Path | Access | Purpose |
|---|---|---|---|
| `POST` | `/api/auth/register` | Public, rate-limited | Create customer account |
| `POST` | `/api/auth/login` | Public, rate-limited | Create authenticated session |
| `POST` | `/api/auth/logout` | Session | Revoke current session |
| `GET` | `/api/auth/me` | Public | Current user summary |
| `POST` | `/api/auth/forgot-password` | Public, rate-limited | Email one-time reset link |
| `POST` | `/api/auth/reset-password` | Public | Reset password with token and revoke sessions |
| `POST` | `/api/auth/verify-email` | Public | Verify email token |
| `POST` | `/api/newsletter` | Public, rate-limited | Store newsletter signup |
| `GET` | `/api/categories` | Public | List categories |
| `GET` | `/api/products?q=&category=&min=&max=&sort=&page=` | Public | Search, filter, sort and paginate products |
| `GET` | `/api/products/:slug` | Public | Product details and reviews |
| `GET`, `POST`, `PATCH`, `DELETE` | `/api/cart` | Customer | View and change current cart |
| `GET`, `POST` | `/api/addresses` | Customer | List/create shipping addresses |
| `GET`, `POST` | `/api/orders` | Customer | Order history and checkout |
| `POST` | `/api/guest-orders` | Public, same-origin and rate-limited | Place one-product COD order from a product landing page |
| `POST` | `/api/reviews` | Customer with delivered purchase | Create/update product review |
| `GET`, `POST`, `DELETE` | `/api/wishlist` | Customer | View and change wishlist |
| `GET` | `/api/admin/dashboard` | Admin | Marketplace metrics and daily/monthly sales summaries |
| `GET` | `/api/admin/marketing` | Admin | Meta configuration status and product-wise order/delivered-sales totals |
| `POST` | `/api/admin/products` | Admin | Create product |
| `GET` | `/api/admin/products/list` | Admin | Product and category management data |
| `PATCH`, `DELETE` | `/api/admin/products/:id` | Admin | Edit, archive, or delete product (orders keep product history) |
| `POST` | `/api/admin/categories` | Admin | Create a product category |
| `PATCH`, `DELETE` | `/api/admin/categories/:id` | Admin | Rename or delete an unused category |
| `GET`, `POST` | `/api/admin/banners` | Admin | List/create homepage promotions |
| `PATCH`, `DELETE` | `/api/admin/banners/:id` | Admin | Show, hide, or delete a promotion |
| `GET` | `/api/banners` | Public | List active homepage promotions |
| `GET` | `/api/admin/orders` | Admin | List orders |
| `GET` | `/api/admin/orders/:id` | Admin | View order/customer/address/payment snapshots |
| `PATCH` | `/api/admin/orders/:id` | Admin | Change order status and notify customer |
| `GET` | `/api/admin/orders/export` | Admin | Download order CSV |
| `GET` | `/api/admin/customers` | Admin | List customers and order counts |
| `GET`, `POST` | `/api/admin/coupons` | Admin | List/create coupons |
| `PATCH` | `/api/admin/coupons/:id` | Admin | Enable or disable a coupon |
| `GET` | `/api/admin/vendors` | Admin | List vendor applications |
| `PATCH` | `/api/admin/vendors/:id` | Admin | Approve/suspend vendor |
| `GET`, `POST`, `PATCH` | `/api/delivery-zones` | Public read, admin write | Read delivery options or configure one of three fixed fee tiers |
| `POST` | `/api/vendor/apply` | Customer/vendor | Submit or update seller application |
| `GET`, `POST` | `/api/vendor/products` | Approved vendor | List/create own vendor products |
| `PATCH` | `/api/vendor/products/:id` | Approved vendor | Edit own product price and stock |
| `POST`, `DELETE` | `/api/upload` | Admin/approved vendor | Server-signed Cloudinary upload and owned product-image deletion |
| `POST` | `/api/coupons/validate` | Customer | Validate coupon against current cart and delivery fee |

## Bangladesh location data

The district/upazila selector is bundled from `bangladesh-location-data` (MIT-licensed). The source package describes its data as compiled from public administrative sources; this project has not independently certified the entries against a current government registry. The original license is included at `public/data/bangladesh-location-data-LICENSE.txt`. Verify district spellings and boundaries with an authoritative source before relying on them for courier zoning.

## Quality checks

```sh
npm run typecheck
npm test
npm run build
npm audit
```

The focused automated tests cover slug generation, payment fail-closed behavior, decimal money conversion, coupon limits, Bangladesh location data, Meta Pixel event gating/purchase deduplication, vendor image ownership, guest customer summaries, and Conversions API secret redaction. Database-backed integration tests should use a disposable PostgreSQL database; never run destructive test setup against production.

## Deployment source ZIP

The `airo-xpress-production.zip` archive is a source package, not a prebuilt or standalone server. It includes the application, static assets, Prisma schema/migrations/seed, package manifest and lockfile, deployment configuration, tests, and safe example environment files. Hosting must still install dependencies and build the Next.js application.

The archive excludes `node_modules`, `.next`, `.open-next`, `.wrangler`, `.git`, editor settings, build/test caches, logs, local `.env`/`.dev.vars` files, and TypeScript build metadata. Keep real credentials in the hosting provider's secret manager; do not add them to the ZIP. After extracting it, configure the required environment variables, run `npm ci` and `npm run build`, then apply database migrations as a separate controlled deployment step with `npm run db:deploy`.

## Deployment

### Vercel

1. Import the project repository into Vercel and select the Next.js framework. The checked-in `vercel.json` sets `npm ci` and `npm run build`; the build script generates Prisma Client before building Next.js.
2. Add `DATABASE_URL`, `DIRECT_URL`, and `APP_URL` as encrypted environment variables for each Vercel environment you will use. For Neon, `DATABASE_URL` must be the pooled URL and `DIRECT_URL` the direct, non-pooled URL. Keep both server-side; never use a `NEXT_PUBLIC_` prefix. Set `APP_URL` to the canonical HTTPS deployment URL, not `http://localhost:3000`; production Vercel builds reject a localhost `APP_URL`.
3. Before directing production traffic to a release, run `npx prisma migrate deploy` once from a trusted release job or local shell configured with the production URLs. Do not put database migrations in the Vercel build command, where concurrent builds could race.
4. Configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and `CLOUDINARY_API_SECRET` to enable product image uploads. Without them the upload API deliberately returns an unavailable response. Configure `RESEND_API_KEY` and `EMAIL_FROM` if email verification and password-reset delivery are required.
5. Bootstrap the administrator through a protected one-time seed operation with `ADMIN_EMAIL` and a unique `ADMIN_PASSWORD` (at least 14 characters). Do not put the password in source control or run the seed as part of every deployment; the seed also configures the default delivery fees.
6. Set `APP_URL` to the canonical HTTPS deployment origin. Review the project’s Vercel function-duration limits for the checkout route, which allows up to 30 seconds for a remote database transaction.
7. Enable Neon backups and point-in-time recovery, restrict production database access, and test restores only against a separate recovery database.
8. For Meta ads, create a dataset/Pixel in Meta Events Manager and set `NEXT_PUBLIC_META_PIXEL_ID` in the Vercel Production environment (and Preview only if needed), then redeploy. The ID is public; do not put a Meta access token in this variable. To enable server-side Purchase events, also configure `META_CAPI_ACCESS_TOKEN` and a Graph API version currently supported by Meta as `META_CAPI_GRAPH_API_VERSION`; optionally set `META_CAPI_TEST_EVENT_CODE` to test with Events Manager. Verify received events and deduplication in Events Manager before relying on campaign reporting. Do not send customer events until your privacy notice and consent requirements are addressed.

Vercel deployment is not complete until the project has been imported, its environment variables configured, and the production domain and external providers tested. This workspace does not contain a Git remote or Vercel account configuration.

### Cloudflare Workers (full-stack Next.js)

This application is a server-rendered Next.js marketplace, not a static site. Do not use the Cloudflare Pages drag-and-drop uploader or upload the project root: the app requires its Worker runtime for API routes, authentication, PostgreSQL access, checkout, and admin/vendor features. The OpenNext build bundles the Worker and static assets without uploading `node_modules`.

The Cloudflare Worker uses the Neon Prisma adapter. Configure `DATABASE_URL` as a pooled Neon PostgreSQL connection string; keep `DIRECT_URL` for Prisma CLI migrations only. Standard Node.js hosting continues to use the regular Prisma client.

1. Connect the project repository to Cloudflare Workers Builds, or use Wrangler from this project after authenticating with `npx wrangler login`. The Worker is configured as `airo-xpress`; set up a custom domain in Cloudflare after the first deployment.
2. Set Worker secrets without committing them:

   ```sh
   npx wrangler secret put DATABASE_URL
   npx wrangler secret put APP_URL
   npx wrangler secret put RESEND_API_KEY
   npx wrangler secret put EMAIL_FROM
   npx wrangler secret put META_CAPI_ACCESS_TOKEN
   npx wrangler secret put META_CAPI_GRAPH_API_VERSION
   npx wrangler secret put META_CAPI_TEST_EVENT_CODE
   npx wrangler secret put CLOUDINARY_CLOUD_NAME
   npx wrangler secret put CLOUDINARY_API_KEY
   npx wrangler secret put CLOUDINARY_API_SECRET
   ```

   Enter the values when prompted; omit optional provider secrets for features you are not enabling. `APP_URL` must be the canonical HTTPS origin. Set `NEXT_PUBLIC_META_PIXEL_ID` as a public build-time variable for the Worker build; it is not a secret. Never place production secrets in `wrangler.jsonc` or source control.
3. Before deploying, run `npm run db:deploy` once from a trusted environment configured with both production `DATABASE_URL` and `DIRECT_URL`. Run `npm run db:seed` once to initialize categories, delivery tiers, and the optional initial admin. Do not run these commands against production casually or as part of every Worker build.
4. Preview in the Workers runtime with `npm run preview`, then deploy with `npm run deploy`. Alternatively, `npm run upload` uploads a Worker version without immediately promoting it. These commands create `.open-next/`; they do not produce a folder for Pages drag-and-drop.
5. The Worker has an `IMAGES` binding for Next.js image optimization. Enable Cloudflare image transformations for the account/zone before relying on optimized Next.js images; Cloudflare may charge for image services.

For local Worker preview, copy `.dev.vars.example` to `.dev.vars`, set a pooled Neon `DATABASE_URL` and a local `APP_URL`, then run `npm run preview`. `.dev.vars` is ignored by Git and supplies Worker runtime variables. `NEXT_PUBLIC_META_PIXEL_ID` is inlined by Next.js at build time, so provide it in the build environment (or a local `.env`) before running the preview build; setting it only in `.dev.vars` is not sufficient. This project has not been deployed to a Cloudflare account from this workspace; verify production secrets, database access, email, image transformations, and custom-domain routing before directing customers to it.

### Other deployment targets

1. Provision PostgreSQL and set production `DATABASE_URL`, `DIRECT_URL`, `APP_URL`, and email/storage configuration in the hosting provider's secret manager. For Neon, use the pooled connection string for `DATABASE_URL` and the non-pooled connection string for `DIRECT_URL`.
2. Configure `ADMIN_EMAIL` and a unique `ADMIN_PASSWORD`.
3. Run `npm ci` and `npm run db:generate` in the build. Run `npm run db:deploy` as a controlled release/migration step before the new application version receives traffic. Run `npm run db:seed` once to initialize categories, delivery tiers, and the optional initial admin.
4. Build and start with `npm run build` and `npm run start` (or use the provider's Next.js deployment support).
5. Configure the reverse proxy to overwrite `X-Forwarded-For`; the rate limiter keys by that header.
6. Configure provider callback URLs and security monitoring before adding any digital-payment adapter. Set `APP_URL` to the canonical HTTPS origin.
7. Enable the database provider's automated backups and point-in-time recovery where available. Document retention, restrict restore access, and periodically restore a backup into a separate database and verify the restored schema/orders before opening traffic.

`next.config.mjs` sets baseline security headers. Use HTTPS in production; cookies are marked `Secure` automatically in production mode. Apply the committed SQL migration with Prisma before serving the app.

For a manual PostgreSQL backup, use the provider's recommended tooling or `pg_dump --format=custom --file=airo-xpress.dump "$DATABASE_URL"`. Restore only into a separate recovery database first with `pg_restore --no-owner --dbname="$RESTORE_DATABASE_URL" airo-xpress.dump`; validate the restored schema and representative orders before directing application traffic to it. Never test restore commands against the live production URL.

The Meta Pixel ID is intentionally public. Keep `META_CAPI_ACCESS_TOKEN` as a server secret. Configure `META_CAPI_GRAPH_API_VERSION` to a version Meta currently supports, and use a test event code only while verifying delivery in Events Manager. This project does not create campaigns or claim that test events were received.

### Docker Compose (local/self-hosted)

Copy `.env.example` to `.env`, replace `POSTGRES_PASSWORD` with a unique alphanumeric password, and set `APP_URL` (`http://localhost:3000` for local use; the canonical HTTPS origin for production). Compose refuses to start without an explicit database password. The app port is bound to host loopback; put a TLS-terminating reverse proxy on the same host in front of it. The optional `NEXT_PUBLIC_META_PIXEL_ID` is passed as a Docker build argument; CAPI settings are passed to the app container at runtime. Then run `docker compose up --build`. The app container applies committed migrations after PostgreSQL passes its health check. In a separate shell, create the initial categories, delivery tiers, and (if `ADMIN_EMAIL` and `ADMIN_PASSWORD` are set in `.env`) administrator:

```sh
docker compose exec app npm run db:seed
```

The Compose file is a convenient single-host setup, not a substitute for production secret management, backups, TLS termination, and monitoring.

## Known gaps before a full production launch

- bKash/Nagad/card provider adapters and signed payment callback verification are deliberately not implemented. Credentials alone do not enable them.
- Phone/SMS verification, email resend flow, return/refund decisions and payment reversal, vendor commission settlement/withdrawal processing, delivery-person assignment, and carrier integrations still need provider and operational workflows.
- General CMS pages, returns/refund decisions, delivery-person assignment, and dedicated review moderation are not yet exposed in the admin UI.
- Search has query/category/price filters and sorting; brand/rating controls, autocomplete, and dedicated inventory facets remain future work.
- In-memory rate limiting is not used; the current limiter is PostgreSQL-backed. Ensure trusted infrastructure controls forwarded-IP headers and monitor database cleanup/retention.
- Live Neon database migration, customer registration/login, admin product creation, checkout calculations, COD order details, admin visibility, and persistence across an application restart were verified during development. Product image upload remains unavailable until Cloudinary credentials are configured.

These are intentional boundaries rather than success-shaped placeholders: do not advertise or activate unavailable workflows until their implementation and acceptance tests are complete.
