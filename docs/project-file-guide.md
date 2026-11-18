# StayEase project file guide

This is a PHP and MySQL website. PHP builds each page and handles server-side requests, MySQL stores the system records, CSS controls appearance, and JavaScript handles small browser interactions.

## Main files

- `index.php` — The website's main PHP entry point. It handles sign-in, registration, public homestay search, page routing, and customer booking drafts. It loads the database-backed staff and customer modules.
- `customer-management.php` — Staff customer directory and profile pages. Search, account edits, customer registration, and deactivate/reactivate actions use MySQL.
- `module-actions.php` — Server-side operations for homestay, promotion, pricing, booking, availability, payment, review, and profile forms. It validates input and writes changes through PDO.
- `live-modules.php` — Database-backed pages for homestays, bookings, availability blocks, promotions and pricing rules, payments, invoices, reviews, and customer profiles.
- `screens.php` — The remaining visual mockup screens used in the report catalogue. Some screens, such as the AI description generator, are still examples and are not connected to an AI service.
- `database/stayease.sql` — SQL instructions that create the `stayease` database, tables, relationships, indexes, sample homestays and accounts, and other starting data. It is not the live database itself. Import it into MySQL using phpMyAdmin.
- `assets/stayease-logo.png` — The StayEase Homestay logo image supplied for the website.
- `assets/style.css` — Main website styles: layout, typography, colors, buttons, homestay cards, and responsive behavior.
- `assets/modules.css` — Styles for the report mockup and module-specific screens.
- `assets/app.js` — Browser-side interactions such as the mobile menu, date input checks, save-heart appearance, and temporary notification dismissal.
- `docs/mockup-screen-guide.md` — Descriptions and routes for the report's categorized mockup screens.
- `README.md` — Setup instructions and an overview of the current project.
- `.env` — Local configuration file placeholder. Database settings currently default to XAMPP's `stayease` database, `root` user, and an empty password; the app reads environment variables when Apache provides them.
- `.gitignore` — Keeps the local `.env` settings and uploaded homestay images out of Git commits.
- `index.php.txt` — A leftover PHP hello-world text file; the website does not load it. `index.php` is the actual site entry point.
- `New folder/` — An empty folder with no effect on the running website.

## Important distinction

The SQL file describes and seeds the database when imported; it is not the live database itself. Connected forms write to MySQL. Payment methods in this project are simulated for the assignment and do not process real money. A database import is required before these features can store or retrieve records.

## Current visual palette

- Main background: `#F5F2EB`
- Secondary background: `#EAE3D2`
- Primary text: `#1C3322`
- Secondary text: `#5B6B5F`
- Accent: `#B58A46` · hover: `#9A7233`
- Success: `#3F7D4E` · warning: `#C98A1B` · danger: `#B3472F` · info: `#3B6F8F`
