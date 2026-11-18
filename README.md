# StayEase

StayEase is a PHP and MySQL homestay booking website prototype based on the supplied Figma Make design. It uses the existing `database/stayease.sql` data model and adds persistent, per-customer booking drafts.

## Run locally with XAMPP

1. Start Apache and MySQL in the XAMPP Control Panel.
2. Import `database/stayease.sql` through phpMyAdmin. The SQL file recreates the `stayease` database and its demo data.
3. Open `http://localhost/StayEase/`.
4. Optional database overrides can be set in the Apache environment: `STAYEASE_DB_HOST`, `STAYEASE_DB_NAME`, `STAYEASE_DB_USER`, and `STAYEASE_DB_PASSWORD`. The defaults are `127.0.0.1`, `stayease`, `root`, and an empty password.

On its first database connection, the site creates `booking_drafts` if it is missing. Drafts belong to a user, retain homestay/date/guest/promo/request details, and do not reserve dates. If MySQL is unavailable, the public discovery pages show sample stays; account and draft persistence need MySQL.

Demo accounts in the supplied SQL use password `Password123`:

- Staff: `admin@stayease.my`
- Customer: `alya@example.com`

## Included screens

- Responsive public pages for home, homestay search, property details, sign-in, registration, profile and bookings.
- `?page=prototype` screen catalogue with 38 labeled screen concepts across all six modules.
- Staff/customer mockup pages for customer management, homestay inventory and the AI description editor, booking and availability, promotions, payments and invoices, and reviews.
- `docs/mockup-screen-guide.md` contains a categorized explanation and route for each of the 38 screens, plus screenshot capture guidance.
- StayEase branding, MYR sample data, no customer AI recommendations or chatbot, and predefined staff accounts in the SQL seed.

See [`docs/project-file-guide.md`](docs/project-file-guide.md) for a plain-language explanation of each project file and the current boundary between working PHP/MySQL flows and visual-only mockup screens. The supplied StayEase Homestay logo and palette are in use across the interface.

Staff pages for customer, homestay, booking and availability, promotions and pricing rules, payment review, and review moderation are connected to the database. Payment handling is simulated for the coursework prototype; it does not charge a real payment method.

The module catalogue pages are a visual prototype and use representative sample values; their buttons illustrate proposed actions and do not perform database updates. The existing customer registration/login, homestay browsing, and per-customer draft saving remain connected to PHP/MySQL.

## Mockup screenshots for the assignment

Open `http://localhost/StayEase/?page=prototype` and select screens by module. Capture at 100% browser zoom and a desktop viewport of at least 1366 × 768. The guide in `docs/mockup-screen-guide.md` provides a ready-to-use title, route and explanation for each screen.
