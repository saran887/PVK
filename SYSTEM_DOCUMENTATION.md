# System Documentation - PKV2 Distribution Management System

## Table of Contents
1. [Database Structure](#database-structure)
2. [System Flow Diagram](#system-flow-diagram)
3. [Use Case Diagram](#use-case-diagram)
4. [Data Flow Diagram - Level 0](#data-flow-diagram---level-0)
5. [Data Flow Diagram - Level 1](#data-flow-diagram---level-1)
6. [Entity Relationship Diagram](#entity-relationship-diagram)

---

## 1. Database Structure

### Firebase Firestore Collections

#### 1.1 Users Collection
**Collection:** `users`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| name | String | Yes | - | User's full name |
| email | String | Yes | - | User's email (auto-generated) |
| phone | String | Yes | - | User's phone number |
| code | String | Yes | - | 4-digit login code |
| role | String | Yes | - | OWNER, ADMIN, SALES, BILLING, DELIVERY |
| password | String | Yes | - | Auto-generated password |
| isActive | Boolean | Yes | true | Account status |
| assignedRoutes | Array\<String\> | Yes | [] | Assigned route IDs |
| locationId | String | Optional | '' | Location reference |
| locationName | String | Optional | '' | Location name |
| createdAt | Timestamp | Yes | serverTimestamp | Creation date |
| updatedAt | Timestamp | Yes | serverTimestamp | Last update |

**Indexes:** code, role, isActive, locationId

---

#### 1.2 Shops Collection
**Collection:** `shops`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| name | String | Yes | - | Shop name |
| ownerName | String | Yes | - | Shop owner name |
| address | String | Yes | - | Shop address |
| phone | String | Yes | - | Contact phone |
| gstNumber | String | Optional | '' | GST number |
| locationId | String | Yes | - | Location reference |
| locationName | String | Yes | - | Location name |
| isActive | Boolean | Yes | true | Shop status |
| createdAt | Timestamp | Yes | serverTimestamp | Creation date |
| updatedAt | Timestamp | Yes | serverTimestamp | Last update |

**Indexes:** locationId, isActive, name

---

#### 1.3 Products Collection
**Collection:** `products`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| productId | String | Yes | - | Custom product ID |
| itemCode | String | Optional | '' | Alternative code |
| name | String | Yes | - | Product name |
| weight | String | Optional | '0' | Weight value |
| weightUnit | String | Optional | 'kg' | Weight unit |
| quantity | String | Optional | '0' | Quantity value |
| quantityUnit | String | Optional | 'pcs' | Quantity unit |
| buyingPrice | Number | Yes | 0.0 | Purchase price |
| sellingPrice | Number | Yes | 0.0 | Selling price |
| price | Number | Optional | - | Same as sellingPrice |
| gstRate | Number | Optional | 0.0 | GST rate % |
| hsnCode | String | Optional | '' | HSN code |
| category | String | Yes | - | Category name |
| description | String | Optional | '' | Description |
| isActive | Boolean | Yes | true | Product status |
| createdAt | Timestamp | Yes | serverTimestamp | Creation date |
| updatedAt | Timestamp | Yes | serverTimestamp | Last update |

**Indexes:** productId, category, isActive, name

---

#### 1.4 Categories Collection
**Collection:** `categories`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| name | String | Yes | - | Category name |
| createdAt | Timestamp | Yes | serverTimestamp | Creation date |

**Indexes:** name

---

#### 1.5 Orders Collection
**Collection:** `orders`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| shopId | String | Yes | - | Shop document ID |
| shopName | String | Yes | - | Shop name |
| shopLocationId | String | Yes | '' | Shop location ID |
| items | Array\<OrderItem\> | Yes | [] | Order items |
| totalAmount | Number | Yes | 0.0 | Total amount |
| totalItems | Number | Yes | 0 | Total item count |
| status | String | Yes | 'pending' | pending/confirmed/billed/delivered/cancelled |
| createdBy | String | Yes | - | User ID |
| createdByName | String | Yes | - | User name |
| createdAt | Timestamp | Yes | serverTimestamp | Order creation |
| updatedAt | Timestamp | Yes | serverTimestamp | Last update |
| billedAt | Timestamp | Optional | - | Billing timestamp |
| deliveredAt | Timestamp | Optional | - | Delivery timestamp |
| paymentStatus | String | Optional | - | paid/pending |
| paymentMethod | String | Optional | - | cash/upi/online/cheque |

**OrderItem Structure (nested):**
```
{
  productId: String,
  customProductId: String,
  productName: String,
  price: Number,
  buyingPrice: Number,
  profit: Number,
  quantity: Number
}
```

**Indexes:** shopId, shopLocationId, status, createdBy, createdAt, billedAt, deliveredAt

---

#### 1.6 Locations Collection
**Collection:** `locations`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| name | String | Yes | - | Location name |
| area | String | Yes | - | Area/region |
| description | String | Optional | '' | Description |
| isActive | Boolean | Yes | true | Location status |
| createdAt | Timestamp | Yes | serverTimestamp | Creation date |
| updatedAt | Timestamp | Yes | serverTimestamp | Last update |

**Indexes:** isActive, name

---

#### 1.7 Expenses Collection
**Collection:** `expenses`

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| title | String | Yes | - | Expense title |
| amount | Number | Yes | - | Expense amount |
| category | String | Yes | - | Expense category |
| date | Timestamp | Yes | - | Expense date |
| description | String | Optional | '' | Description |
| createdAt | Timestamp | Yes | serverTimestamp | Record creation |

**Indexes:** date, category

---

## 2. System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PKV2 DISTRIBUTION MANAGEMENT SYSTEM                 │
│                                  SYSTEM FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────┐
                              │   LOGIN      │
                              │  (4-digit    │
                              │    code)     │
                              └──────┬───────┘
                                     │
                                     ▼
                        ┌────────────────────────┐
                        │  Authentication Check  │
                        │    (Firebase Auth)     │
                        └────────────┬───────────┘
                                     │
                ┌────────────────────┼────────────────────┐
                │                    │                    │
                ▼                    ▼                    ▼
        ┌───────────┐        ┌──────────┐        ┌──────────┐
        │   OWNER   │        │  ADMIN   │        │  SALES   │
        └─────┬─────┘        └────┬─────┘        └────┬─────┘
              │                   │                    │
              │                   │                    │
    ┌─────────┴─────────┐         │           ┌────────┴────────┐
    │                   │         │           │                 │
    ▼                   ▼         ▼           ▼                 ▼
┌─────────┐      ┌──────────┐  ┌────────┐  ┌────────┐    ┌──────────┐
│Analytics│      │ Expenses │  │Manage  │  │Shop    │    │  Create  │
│ Reports │      │ Tracking │  │Users   │  │List    │    │  Order   │
└─────────┘      └──────────┘  │Products│  └────────┘    └─────┬────┘
                                │Shops   │                      │
                                │Location│                      │
                                └────────┘                      ▼
                                                        ┌────────────────┐
                ┌──────────────────────────────────────│  ORDER FLOW    │
                │                                       └────────────────┘
                │                                               │
                ▼                                               ▼
        ┌───────────┐                               ┌──────────────────┐
        │  BILLING  │◄──────────────────────────────│ Order Created    │
        └─────┬─────┘                               │ (Status: pending)│
              │                                     └──────────────────┘
              │                                               │
              │                                               ▼
    ┌─────────┴─────────┐                          ┌──────────────────┐
    │                   │                          │ Billing Reviews  │
    ▼                   ▼                          │ & Adjusts Prices │
┌─────────┐      ┌──────────┐                     └─────────┬────────┘
│Pending  │      │Processed │                               │
│Orders   │      │Orders    │                               ▼
└─────────┘      └──────────┘                    ┌──────────────────────┐
      │                 │                        │ Generate Bill/Invoice│
      │                 │                        │ (Status: confirmed)  │
      │                 │                        └──────────┬───────────┘
      │                 │                                   │
      └─────────────────┼───────────────────────────────────┘
                        │
                        ▼
                ┌───────────┐
                │ DELIVERY  │
                └─────┬─────┘
                      │
            ┌─────────┴─────────┐
            │                   │
            ▼                   ▼
    ┌──────────────┐    ┌─────────────┐
    │ Ready to     │    │  Delivery   │
    │ Deliver      │    │  History    │
    │ (Status:     │    │ (Status:    │
    │  billed)     │    │  delivered) │
    └──────┬───────┘    └─────────────┘
           │
           ▼
    ┌──────────────┐
    │ Mark as      │
    │ Delivered    │
    │ & Collect    │
    │ Payment      │
    └──────────────┘

                  ┌──────────────────────────────┐
                  │  Firebase Firestore Database │
                  │  • users                     │
                  │  • shops                     │
                  │  • products                  │
                  │  • orders                    │
                  │  • locations                 │
                  │  • categories                │
                  │  • expenses                  │
                  └──────────────────────────────┘
```

---

## 3. Use Case Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              USE CASE DIAGRAM                                │
│                    PKV2 Distribution Management System                       │
└──────────────────────────────────────────────────────────────────────────────┘


    ┌─────────┐                                                   ┌─────────┐
    │         │                                                   │         │
    │ OWNER   │                                                   │  ADMIN  │
    │         │                                                   │         │
    └────┬────┘                                                   └────┬────┘
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ View Analytics & Reports                     │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ Track Business Expenses                      │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ Manage Salary Payments                       │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         └───┤ View All Products, Shops & Users             │◄────────┤
             └──────────────────────────────────────────────┘         │
                                                                       │
             ┌──────────────────────────────────────────────┐         │
             │ Add/Edit/Delete Users                        │◄────────┤
             └──────────────────────────────────────────────┘         │
                                                                       │
             ┌──────────────────────────────────────────────┐         │
             │ Add/Edit/Delete Products                     │◄────────┤
             └──────────────────────────────────────────────┘         │
                                                                       │
             ┌──────────────────────────────────────────────┐         │
             │ Add/Edit/Delete Shops                        │◄────────┤
             └──────────────────────────────────────────────┘         │
                                                                       │
             ┌──────────────────────────────────────────────┐         │
             │ Manage Locations/Routes                      │◄────────┘
             └──────────────────────────────────────────────┘


    ┌─────────┐                                                   ┌─────────┐
    │         │                                                   │         │
    │  SALES  │                                                   │ BILLING │
    │         │                                                   │         │
    └────┬────┘                                                   └────┬────┘
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ View Assigned Shops by Location              │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ Browse Product Catalog                       │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │   ┌──────────────────────────────────────────────┐         │
         ├───┤ Create New Order                             │         │
         │   └──────────────────┬───────────────────────────┘         │
         │                      │                                     │
         │   ┌──────────────────▼───────────────────────────┐         │
         ├───┤ View My Orders (Created Orders)              │         │
         │   └──────────────────────────────────────────────┘         │
         │                                                             │
         │                                                             │
         │                                                             │
         │                      ┌──────────────────────────┐          │
         │                      │ Review Pending Orders    │◄─────────┤
         │                      └──────────────────────────┘          │
         │                                                             │
         │                      ┌──────────────────────────┐          │
         │                      │ Adjust Product Prices    │◄─────────┤
         │                      └──────────────────────────┘          │
         │                                                             │
         │                      ┌──────────────────────────┐          │
         │                      │ Generate Bill/Invoice    │◄─────────┤
         │                      └──────────────────────────┘          │
         │                                                             │
         │                      ┌──────────────────────────┐          │
         │                      │ Confirm Order            │◄─────────┤
         │                      └──────────────────────────┘          │
         │                                                             │
         │                      ┌──────────────────────────┐          │
         │                      │ View Processed Orders    │◄─────────┘
         │                      └──────────────────────────┘


    ┌──────────┐
    │          │
    │ DELIVERY │
    │          │
    └────┬─────┘
         │
         │   ┌──────────────────────────────────────────────┐
         ├───┤ View Ready to Deliver Orders                 │
         │   └──────────────────────────────────────────────┘
         │
         │   ┌──────────────────────────────────────────────┐
         ├───┤ Mark Order as Delivered                      │
         │   └──────────────────────────────────────────────┘
         │
         │   ┌──────────────────────────────────────────────┐
         ├───┤ Record Payment Collection                    │
         │   └──────────────────────────────────────────────┘
         │
         │   ┌──────────────────────────────────────────────┐
         └───┤ View Delivery History                        │
             └──────────────────────────────────────────────┘


             ┌──────────────────────────────────────────────┐
             │ <<system>>                                   │
             │ Firebase Authentication                      │
             └──────────────────────────────────────────────┘
                                 ▲
                                 │
             ┌───────────────────┴──────────────────────────┐
             │ Login with 4-digit Code                      │
             └──────────────────────────────────────────────┘
                      ▲              ▲              ▲
                      │              │              │
              ┌───────┴───┐   ┌──────┴─────┐  ┌────┴──────┐
              │ All Users │   │ All Users  │  │ All Users │
              └───────────┘   └────────────┘  └───────────┘
```

---

## 4. Data Flow Diagram - Level 0 (Context Diagram)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       DATA FLOW DIAGRAM - LEVEL 0                            │
│                    PKV2 Distribution Management System                       │
└──────────────────────────────────────────────────────────────────────────────┘


                                  ┌─────────────┐
                                  │   OWNER     │
                                  └──────┬──────┘
                                         │
                        View Reports &   │   Manage Expenses
                        Analytics        │   Track Salaries
                                         │
                                         ▼
        ┌───────────┐            ┌──────────────────┐           ┌──────────┐
        │   ADMIN   │───────────▶│                  │◄──────────│  SALES   │
        │           │  Manage    │  PKV2 DISTRI-    │  Create   │          │
        │           │  Users,    │  BUTION          │  Orders,  │          │
        │           │  Products, │  MANAGEMENT      │  View     │          │
        │           │  Shops,    │  SYSTEM          │  Shops    │          │
        │           │  Locations │                  │           │          │
        └───────────┘            │     (Core)       │           └──────────┘
                                 │                  │
                                 └───────▲──────────┘
                                         │
                   Process Orders,       │      Mark Delivered,
                   Generate Bills,       │      Collect Payment,
                   Adjust Prices         │      Update Status
                                         │
                                  ┌──────┴──────┐
                                  │   BILLING   │
                                  │  & DELIVERY │
                                  └─────────────┘

                              External Systems:
                    ┌──────────────────────────────┐
                    │  Firebase Authentication     │
                    │  Firebase Firestore Database │
                    │  Firebase Storage            │
                    └──────────────────────────────┘

Data Flows:
═══════════
• User Credentials        → System → Authentication Status
• Product Information     → System → Product Catalog
• Shop Information        → System → Shop Database
• Order Details           → System → Order Processing
• Bill/Invoice Data       → System → Generated Bills
• Delivery Status         → System → Updated Order Status
• Analytics Data          → System → Reports & Insights
• Expense Records         → System → Financial Tracking
```

---

## 5. Data Flow Diagram - Level 1

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       DATA FLOW DIAGRAM - LEVEL 1                            │
│                    PKV2 Distribution Management System                       │
└──────────────────────────────────────────────────────────────────────────────┘


┌─────────┐
│ ADMIN   │────┐
└─────────┘    │
               │ User Details
               │
               ▼
         ┌──────────────┐         User Data          ┌──────────────┐
         │   Process    │────────────────────────────▶│   Users      │
         │   1.1        │                             │  Database    │
         │ User Mgmt    │◄────────────────────────────│   (D1)       │
         └──────────────┘      User Info              └──────────────┘
               │
               │ User Created/Updated
               │
               ▼
         ┌──────────────┐
         │ Firebase     │
         │ Auth Service │
         └──────────────┘


┌─────────┐
│ ADMIN   │────┐
└─────────┘    │
               │ Product Details
               │
               ▼
         ┌──────────────┐      Product Data          ┌──────────────┐
         │   Process    │────────────────────────────▶│  Products    │
         │   1.2        │                             │  Database    │
         │Product Mgmt  │◄────────────────────────────│   (D2)       │
         └──────────────┘      Product Info           └──────────────┘
                                      │
                                      │ Category Data
                                      ▼
                               ┌──────────────┐
                               │ Categories   │
                               │  Database    │
                               │   (D3)       │
                               └──────────────┘


┌─────────┐
│ ADMIN   │────┐
└─────────┘    │
               │ Shop Details
               │
               ▼
         ┌──────────────┐       Shop Data            ┌──────────────┐
         │   Process    │────────────────────────────▶│   Shops      │
         │   1.3        │                             │  Database    │
         │  Shop Mgmt   │◄────────────────────────────│   (D4)       │
         └──────────────┘       Shop Info             └──────────────┘
               │
               │ Location Reference
               │
               ▼
         ┌──────────────┐
         │  Locations   │
         │  Database    │
         │   (D5)       │
         └──────────────┘


┌─────────┐
│  SALES  │────┐
└─────────┘    │
               │ Order Request
               │
               ▼
         ┌──────────────┐
         │   Process    │
         │   2.1        │       Read Products         ┌──────────────┐
         │Order Creation│◄────────────────────────────│  Products    │
         └──────┬───────┘                             │  Database    │
                │                                     └──────────────┘
                │ New Order
                │
                ▼
         ┌──────────────┐       Order Data           ┌──────────────┐
         │   Process    │────────────────────────────▶│   Orders     │
         │   2.2        │                             │  Database    │
         │Order Storage │                             │   (D6)       │
         └──────────────┘                             └──────────────┘
                                                             │
                                                             │ Order Status:
                                                             │ pending
                                                             ▼
┌─────────┐                                            ┌──────────────┐
│ BILLING │───────────────────────────────────────────▶│   Process    │
└─────────┘        Review Order                        │   3.1        │
                                                        │ Billing      │
                 ┌──────────────────────────────────────│ Processing   │
                 │ Updated Order                       └──────┬───────┘
                 │ (Status: confirmed/billed)                 │
                 │                                            │ Adjust Prices
                 ▼                                            │
         ┌──────────────┐                                    │
         │   Orders     │                                    │
         │  Database    │◄───────────────────────────────────┘
         │   (D6)       │       Update Product Prices
         └──────┬───────┘              │
                │                      ▼
                │              ┌──────────────┐
                │              │  Products    │
                │              │  Database    │
                │              └──────────────┘
                │
                │ Order Status: billed
                │
                ▼
┌──────────┐
│ DELIVERY │──────┐
└──────────┘      │
                  │ Ready to Deliver
                  │
                  ▼
         ┌──────────────┐       Read Orders          ┌──────────────┐
         │   Process    │◄───────────────────────────│   Orders     │
         │   4.1        │                            │  Database    │
         │ Delivery     │                            │   (D6)       │
         │ Management   │────────────────────────────▶              │
         └──────────────┘  Update Status: delivered  └──────────────┘
                │           Record Payment
                │
                │ Delivery Confirmation
                │
                ▼
         ┌──────────────┐
         │  Shop/       │
         │  Customer    │
         └──────────────┘


┌─────────┐
│  OWNER  │────┐
└─────────┘    │
               │ Request Analytics
               │
               ▼
         ┌──────────────┐
         │   Process    │      Read All Data         ┌──────────────┐
         │   5.1        │◄───────────────────────────│  Orders      │
         │ Analytics    │                            │  Products    │
         │ & Reports    │◄───────────────────────────│  Shops       │
         │              │                            │  Users       │
         │              │◄───────────────────────────│  Expenses    │
         └──────┬───────┘                            └──────────────┘
                │
                │ Generate Reports
                │
                ▼
         ┌──────────────┐
         │  Dashboard   │
         │  Reports     │
         └──────────────┘


         ┌──────────────┐
         │   Process    │      Expense Data          ┌──────────────┐
         │   5.2        │────────────────────────────▶│  Expenses    │
         │ Expense      │                             │  Database    │
         │ Tracking     │◄────────────────────────────│   (D7)       │
         └──────────────┘      Expense Records        └──────────────┘
                ▲
                │
                │ Add/View Expenses
                │
         ┌──────┴───────┐
         │   OWNER      │
         └──────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA STORES (Databases)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ D1: Users Database      - User accounts and roles                           │
│ D2: Products Database   - Product catalog                                   │
│ D3: Categories Database - Product categories                                │
│ D4: Shops Database      - Shop/customer information                         │
│ D5: Locations Database  - Geographic locations/routes                       │
│ D6: Orders Database     - All orders and their statuses                     │
│ D7: Expenses Database   - Business expense records                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Entity Relationship Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                       ENTITY RELATIONSHIP DIAGRAM                            │
│                    PKV2 Distribution Management System                       │
└──────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────┐
│       LOCATIONS         │
│─────────────────────────│
│ PK: id                  │◄─────────┐
│─────────────────────────│          │
│ name         : String   │          │ 1
│ area         : String   │          │
│ description  : String   │          │ belongs to
│ isActive     : Boolean  │          │
│ createdAt    : Timestamp│          │
│ updatedAt    : Timestamp│          │
└─────────────────────────┘          │
         ▲                           │
         │ 1                         │
         │                           │
         │ belongs to                │
         │                           │
         │ *                         │
┌────────┴────────────────┐          │
│        SHOPS            │          │
│─────────────────────────│          │
│ PK: id                  │          │
│─────────────────────────│          │
│ name         : String   │          │
│ ownerName    : String   │          │
│ address      : String   │          │
│ phone        : String   │          │
│ gstNumber    : String   │          │
│ FK: locationId: String  │──────────┘
│ locationName : String   │
│ isActive     : Boolean  │
│ createdAt    : Timestamp│
│ updatedAt    : Timestamp│
└────────┬────────────────┘
         │ 1
         │
         │ places
         │
         │ *
┌────────▼────────────────┐
│        ORDERS           │
│─────────────────────────│
│ PK: id                  │
│─────────────────────────│
│ FK: shopId   : String   │
│ shopName     : String   │
│ shopLocationId:String   │
│ items        : Array    │──────┐
│ totalAmount  : Number   │      │
│ totalItems   : Number   │      │
│ status       : String   │      │ contains
│ FK: createdBy: String   │──┐   │
│ createdByName: String   │  │   │
│ createdAt    : Timestamp│  │   │ *
│ updatedAt    : Timestamp│  │   │
│ billedAt     : Timestamp│  │   │
│ deliveredAt  : Timestamp│  │   │
│ paymentStatus: String   │  │   │
│ paymentMethod: String   │  │   │
└─────────────────────────┘  │   │
                             │   │
         ┌───────────────────┘   │
         │ created by            │
         │                       │
         │ 1                     │
         │                       │
┌────────▼────────────────┐      │         ┌─────────────────────────┐
│        USERS            │      └────────▶│    ORDER ITEMS          │
│─────────────────────────│                │─────────────────────────│
│ PK: id                  │                │ FK: productId : String  │
│─────────────────────────│                │─────────────────────────│
│ name         : String   │                │ customProductId:String  │
│ email        : String   │                │ productName : String    │
│ phone        : String   │                │ price       : Number    │
│ code         : String   │                │ buyingPrice : Number    │
│ password     : String   │                │ profit      : Number    │
│ role         : String   │                │ quantity    : Number    │
│ isActive     : Boolean  │                └───────────┬─────────────┘
│ assignedRoutes: Array   │                            │
│ FK: locationId: String  │──────────┐                 │ references
│ locationName : String   │          │                 │
│ createdAt    : Timestamp│          │ 1               │ *
│ updatedAt    : Timestamp│          │                 │
└─────────────────────────┘          │         ┌───────▼─────────────┐
                                     │         │     PRODUCTS        │
                                     │         │─────────────────────│
                                     │         │ PK: id              │
┌─────────────────────────┐          │         │─────────────────────│
│      CATEGORIES         │          │         │ productId  : String │
│─────────────────────────│          │         │ itemCode   : String │
│ PK: id                  │          │         │ name       : String │
│─────────────────────────│          │         │ weight     : String │
│ name         : String   │          │         │ weightUnit : String │
│ createdAt    : Timestamp│          │         │ quantity   : String │
└────────┬────────────────┘          │         │ quantityUnit:String │
         │ 1                         │         │ buyingPrice: Number │
         │                           │         │ sellingPrice:Number │
         │ categorizes               │         │ price      : Number │
         │                           │         │ gstRate    : Number │
         │ *                         │         │ hsnCode    : String │
         └───────────────────────────┼────────▶│FK:category : String │
                                     │         │ description: String │
                                     │         │ isActive   : Boolean│
                                     │         │ createdAt  :Timestamp
                                     │         │ updatedAt  :Timestamp
                                     │         └─────────────────────┘
                                     │
                                     │
                                     │ assigned to
                                     │
                                     │
                                     ▼
                                  (implicit)


┌─────────────────────────┐
│       EXPENSES          │
│─────────────────────────│
│ PK: id                  │
│─────────────────────────│
│ title        : String   │
│ amount       : Number   │
│ category     : String   │
│ date         : Timestamp│
│ description  : String   │
│ createdAt    : Timestamp│
└─────────────────────────┘
         ▲
         │
         │ tracks
         │
    (managed by OWNER)


┌─────────────────────────────────────────────────────────────────────────────┐
│                           RELATIONSHIPS SUMMARY                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ 1. LOCATIONS (1) ───< has >───── (Many) SHOPS                              │
│    One location can have multiple shops                                    │
│                                                                             │
│ 2. LOCATIONS (1) ───< assigns >─── (Many) USERS                            │
│    One location can be assigned to multiple users (sales/delivery)         │
│                                                                             │
│ 3. SHOPS (1) ───< places >───── (Many) ORDERS                              │
│    One shop can place multiple orders                                      │
│                                                                             │
│ 4. USERS (1) ───< creates >───── (Many) ORDERS                             │
│    One user (sales) can create multiple orders                             │
│                                                                             │
│ 5. ORDERS (1) ───< contains >─── (Many) ORDER ITEMS                        │
│    One order can contain multiple items                                    │
│                                                                             │
│ 6. PRODUCTS (1) ───< referenced by >─── (Many) ORDER ITEMS                 │
│    One product can be in multiple order items                              │
│                                                                             │
│ 7. CATEGORIES (1) ───< categorizes >─── (Many) PRODUCTS                    │
│    One category can contain multiple products                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘


CARDINALITY NOTATION:
═══════════════════════
│      1      │  = One (exactly one)
│      *      │  = Many (zero or more)
│      1..*   │  = One or more
│     0..1    │  = Zero or one
```

---

## Database Relationships Summary

### Primary Relationships:

1. **Users ↔ Locations** (Many-to-One)
   - A user (sales/delivery) is assigned to one location
   - A location can have multiple users

2. **Shops ↔ Locations** (Many-to-One)
   - Each shop belongs to one location
   - A location can have multiple shops

3. **Orders ↔ Shops** (Many-to-One)
   - Each order is placed by one shop
   - A shop can have multiple orders

4. **Orders ↔ Users** (Many-to-One)
   - Each order is created by one user (sales person)
   - A user can create multiple orders

5. **Orders ↔ Order Items** (One-to-Many)
   - Each order contains multiple items (embedded array)
   - Order items are nested within orders

6. **Products ↔ Order Items** (One-to-Many)
   - Each product can appear in multiple order items
   - Each order item references one product

7. **Products ↔ Categories** (Many-to-One)
   - Each product belongs to one category
   - A category can have multiple products

8. **Expenses** (Standalone)
   - Tracked independently for business expenses
   - No direct foreign key relationships

---

## Query Optimization & Indexes

### Recommended Indexes:

```javascript
// Users Collection
db.users.createIndex({ "code": 1 });
db.users.createIndex({ "role": 1, "isActive": 1 });
db.users.createIndex({ "locationId": 1, "isActive": 1 });

// Shops Collection
db.shops.createIndex({ "locationId": 1, "isActive": 1 });
db.shops.createIndex({ "name": 1 });

// Products Collection
db.products.createIndex({ "productId": 1 });
db.products.createIndex({ "category": 1, "isActive": 1 });
db.products.createIndex({ "name": "text" }); // Text search

// Orders Collection
db.orders.createIndex({ "shopId": 1, "status": 1 });
db.orders.createIndex({ "shopLocationId": 1, "status": 1 });
db.orders.createIndex({ "createdBy": 1, "status": 1 });
db.orders.createIndex({ "status": 1, "createdAt": -1 });
db.orders.createIndex({ "billedAt": -1 });
db.orders.createIndex({ "deliveredAt": -1 });

// Locations Collection
db.locations.createIndex({ "isActive": 1, "name": 1 });

// Categories Collection
db.categories.createIndex({ "name": 1 });

// Expenses Collection
db.expenses.createIndex({ "date": -1 });
db.expenses.createIndex({ "category": 1, "date": -1 });
```

---

## Status Flow

### Order Status Lifecycle:
```
pending → confirmed → billed → delivered → [archived]
                ↓
           cancelled
```

**Status Definitions:**
- `pending`: Order created by sales, awaiting billing review
- `confirmed`: Order confirmed by billing, rates adjusted
- `billed`: Bill generated, ready for delivery
- `delivered`: Order delivered to customer, payment collected
- `cancelled`: Order cancelled (can occur at any stage)

---

## User Roles & Permissions

| Role | Permissions |
|------|-------------|
| **OWNER** | View all analytics, reports, expenses, salaries, products, shops, users |
| **ADMIN** | Manage users, products, shops, locations, categories |
| **SALES** | View assigned shops, create orders, view own orders |
| **BILLING** | Review pending orders, adjust prices, generate bills, confirm orders |
| **DELIVERY** | View ready orders, mark delivered, collect payment, view delivery history |

---

## System Architecture

**Technology Stack:**
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Services
  - Firebase Authentication (user authentication)
  - Cloud Firestore (NoSQL database)
  - Firebase Storage (file storage - if needed for images)
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Platform:** Android, iOS, Web

---

## Data Security

1. **Authentication:** 4-digit code-based authentication via Firebase Auth
2. **Authorization:** Role-based access control (RBAC)
3. **Data Validation:** Client-side and server-side validation
4. **Firestore Rules:** Security rules based on user roles
5. **Password Management:** Auto-generated secure passwords

---

**Document Version:** 1.0
**Last Updated:** December 31, 2025
**System:** PKV2 Distribution Management System
