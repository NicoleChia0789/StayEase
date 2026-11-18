# StayEase Mockup UI Development

This guide is written for Section 4, Mockup UI Development. The prototype screens are grouped by the six system modules. Each screen explanation states its purpose, the information shown and the main user decision supported by the layout.

## Capture setup

Open `http://localhost/StayEase/?page=prototype` in Chrome. Use a desktop viewport of at least 1366 × 768 at 100% browser zoom. Capture each linked screen at its normal browser size; do not zoom in to make text readable. Use a full-page capture or a second capture for long screens when needed. The screen index links are for prototype navigation; buttons that represent business operations are visual mockup controls unless the existing system explicitly implements them.

## Module 1 — Customer Management

### 1. Customer registration

Route: `?page=register`  
This form collects a new customer's full name, email, phone number and password. Required fields and password-length guidance help the customer provide complete account information before registration.

### 2. Customer sign in

Route: `?page=login`  
The sign-in screen provides email and password fields with a clear primary action. It represents the shared login entry for customers and the predefined staff accounts, with the account role determining the destination after login.

### 3. My profile and account settings

Route: `?page=profile`  
The profile screen groups editable contact details, password controls and the account-deactivation area. The deactivation message explains that active bookings must be resolved, and the confirmation panel shows that a password is required before the action.

### 4. Customer directory

Route: `?page=customers`  
Staff can search customers by name, email or phone and filter by active status. The table presents customer identifiers, contact details, booking counts and account status so staff can locate an account and decide which record to review.

### 5. Customer profile and booking history

Route: `?page=customer-detail`  
This staff view combines contact information and an account summary with the customer's booking history. Account-status and password-reset actions are placed beside the customer identity for quick account support.

### 6. Register a customer on behalf

Route: `?page=customer-form`  
Staff can create a customer profile for a phone or walk-in guest using the customer's name, email, phone number and temporary password. The form makes clear that the new account receives the Customer role; staff accounts are predefined and are not created here.

## Module 2 — Homestay Management

### 7. Public home and featured stays

Route: `?`  
The home screen introduces StayEase, presents featured properties and provides destination, date and guest search controls. It directs customers toward browsing the active homestay collection.

### 8. Browse, search and filter homestays

Route: `?page=stays`  
Customers can search by property or destination and narrow the list by state, nightly budget and guest capacity. The property cards show location, rating, price and a route to the full details screen.

### 9. Homestay details

Route: `?page=stay&id=1`  
The details screen presents the selected property's location, rating, photographs, description, capacity, rooms, facilities and nightly price. A date-and-guest panel provides the starting point for planning or saving a booking draft.

### 10. Staff homestay inventory

Route: `?page=homestays-admin`  
Staff can view all listing records in a searchable table, including location, price, guest capacity and listing status. The Add Homestay action leads to the property form, while each row provides an edit route.

### 11. Add or edit homestay

Route: `?page=homestay-form`  
The form groups required property information, price, capacity, bedrooms, bathrooms, facilities, description and listing photographs. A separate status control explains how Maintenance affects customer visibility and booking availability.

### 12. Change listing status or deactivate

Route: `?page=homestay-status`  
This confirmation screen lets staff select a status and record a reason. The warning reminds staff to review future bookings before deactivation and reinforces the soft-delete approach for preserving records.

### 13. AI description generator

Route: `?page=ai-description`  
Staff upload one to five property photos, review the saved details that provide factual context, add optional notes and choose a writing tone. The generated description remains editable, includes a character count and factual-review warning, and provides regenerate, edit and save actions.

## Module 3 — Booking and Availability Management

### 14. Select customer for a staff booking

Route: `?page=booking-flow&step=customer`  
The first step allows staff to search for an existing customer and shows the selected account in a booking-on-behalf-of banner. A link to customer registration covers walk-in guests who do not yet have an account.

### 15. Select homestay

Route: `?page=booking-flow&step=homestay`  
The property-selection step displays available active homestays with location and nightly price. Staff choose the property before entering reservation dates.

### 16. Select dates and guests

Route: `?page=booking-flow&step=dates`  
The date step summarizes the selected homestay and captures check-in, check-out and guest count. An availability message indicates that the dates must be checked before the reservation proceeds.

### 17. Review booking and promotion

Route: `?page=booking-flow&step=review`  
Customers or staff review stay dates, guest count, room charges, pricing-rule discounts and promotion discounts. The total is separated from the line items, and the promotion field shows where a code is entered and validated.

### 18. Payment step in the booking flow

Route: `?page=booking-flow&step=payment`  
The payment step shows the amount due and available payment methods. It also communicates that card information is not stored by StayEase.

### 19. Booking confirmation

Route: `?page=booking-flow&step=confirmation`  
The confirmation ticket shows the booking reference, property, dates, guests and total amount. It also displays the current payment state so the customer understands whether payment verification remains pending.

### 20. My bookings — upcoming

Route: `?page=bookings`  
The My Bookings page organizes upcoming, completed, cancelled and draft reservations in separate tabs. This is the customer's entry point for viewing reservation status and returning to a saved draft.

### 21. Booking details and modify/cancel

Route: `?page=my-booking`  
This customer view displays dates, guests, booking reference, price breakdown and payment state for a confirmed stay. Modify and cancel controls are grouped with the booking summary, while the timeline shows key reservation events.

### 22. My bookings — saved drafts

Route: `?page=bookings&tab=drafts`  
Each draft card is designed to show the homestay, dates, guests, estimated total and last-saved time. Continue, edit and delete actions are accompanied by a clear notice that drafts do not reserve dates.

### 23. Booking history

Route: `?page=booking-history`  
Staff can review bookings from both customers and staff-assisted reservations. Search, status, date and customer fields support record lookup, while the table includes booking ID, guest, property, dates, total and source.

### 24. Booking details and status timeline

Route: `?page=booking-detail`  
The staff detail view combines customer and stay information with the price breakdown and payment state. A status timeline provides an audit-style summary of booking creation, payment submission and the next status action.

### 25. Availability calendar

Route: `?page=availability-calendar`  
Staff can view a monthly calendar for a selected homestay. Distinct visual states identify booked, pending, blocked and available dates, and the legend explains each state.

### 26. Manage blocked dates

Route: `?page=blocked-date-form`  
The form captures a homestay, inclusive date range, reason and optional note for maintenance or private use. An existing-block list supports review and removal of unavailable periods.

## Module 4 — Promotion and Discount Management

### 27. Available customer promotions

Route: `?page=promotions-public`  
Customers can review active offers, discount values, minimum spend and validity periods before booking. Each offer displays its code and a short summary of its eligibility conditions.

### 28. Promotion management

Route: `?page=promotions`  
Staff can search promotion codes and review discount type, minimum requirements, validity dates, redemption count and status. The New Promotion action opens the promotion form.

### 29. Add or edit promotion

Route: `?page=promotion-form`  
The form captures the code, discount type and amount, minimum nights and spend, validity period, usage limit, description and active state. Grouping these fields helps staff verify promotion rules before saving.

## Module 5 — Payment Management

### 30. Customer payment records

Route: `?page=payments-customer`  
Customers can locate payment records by booking or reference and review payment method, amount and status. Each record links to transaction details and the invoice preview.

### 31. Payment details

Route: `?page=payment-detail`  
The transaction summary links a payment to its booking and customer, and displays method, amount, reference and submission time. Staff can compare the submitted receipt preview with the recorded transaction before verifying it.

### 32. Payment verification queue

Route: `?page=payments-admin`  
Staff can filter payment records by status and inspect pending transfers alongside paid transactions. The queue provides a consistent starting point for verification and exception handling.

### 33. Refund or void payment

Route: `?page=refund-payment`  
The payment detail layout exposes staff verification, rejection and refund controls for the selected transaction. This screen keeps the original transaction record visible while staff review its status and remarks.

### 34. E-Invoice preview

Route: `?page=invoice`  
The invoice presents StayEase and customer information, booking reference, homestay, dates, itemized discounts and total paid. The print/download action represents the PDF invoice output required by the system.

## Module 6 — Ratings and Reviews Management

### 35. Homestay reviews

Route: `?page=reviews-public`  
Customers can read verified ratings, written feedback and staff replies for a property. The summary rating and review count appear before individual comments to help customers compare stays.

### 36. My reviews

Route: `?page=reviews-customer`  
Customers can view reviews associated with their completed stays and open the edit action for their own feedback. The completed-stay reference explains when reviews become available.

### 37. Edit review

Route: `?page=review-form`  
The form identifies the homestay and completed stay, then provides a star-rating control and written-comment area. Save and cancel actions make the edit task clear.

### 38. Review moderation and replies

Route: `?page=reviews-admin`  
Staff can search review records, filter visible or hidden content, and identify the customer, property, rating and submission date. Reply and moderation actions are available from each row.

## Prototype scope note

The screen catalogue is a visual UI prototype. Screens use representative StayEase sample data; actions shown on mockup-only pages are presentation controls and do not write to the database. Existing account login, customer registration and draft saving continue to use the application's PHP/MySQL implementation.
