# IMAM DATASUB — Play Store Listing Kit

⚠️ **Fix first:** your support email is currently `abdulmhassan02@gmai.com` (missing the "l" in gmail) in `app_config.dart`. Confirm the real address before submitting — it's used below and in your in-app support screens.

---

## 1. App title (max 30 characters)

```
IMAM DATASUB
```

If you want a subtitle-style title for better search visibility (still under 30 chars):
```
IMAM DATASUB - Data & Bills
```
(27 characters)

---

## 2. Short description (max 80 characters)

```
Buy data, airtime, pay bills & fund your wallet instantly — fast & secure.
```
(76 characters)

---

## 3. Full description (max 4000 characters)

```
IMAM DATASUB is your all-in-one platform for data, airtime, bill payments, and more — fast, secure, and built around your wallet.

💳 FUND YOUR WALLET
Fund your wallet instantly via bank transfer or your dedicated virtual account. Get notified the moment your funding is confirmed.

📶 DATA & AIRTIME
Buy data and airtime for all major Nigerian networks — MTN, Airtel, Glo, and 9mobile — at competitive rates, delivered instantly to any phone number.

💵 AIRTIME TO CASH
Convert excess airtime into wallet cash quickly and easily.

📺 CABLE TV SUBSCRIPTIONS
Renew or subscribe to DStv, GOtv, StarTimes and more without leaving the app.

⚡ ELECTRICITY BILLS
Pay your electricity bills (prepaid and postpaid) for supported distribution companies in seconds.

🎓 JAMB & RESULT CHECKER PINS
Purchase JAMB ePINs and WAEC/NECO result checker PINs for exams and admissions.

💳 RECHARGE & DATA CARDS
Buy recharge cards and data cards in bulk — great for resellers and business owners.

📢 BULK SMS
Send bulk SMS campaigns directly from the app.

🎁 REFERRAL PROGRAM
Invite friends and earn rewards when they join and transact.

🔔 REAL-TIME NOTIFICATIONS
Get instant, personal notifications for every wallet funding, purchase, and transaction — plus important updates and price-change alerts from our team, when they matter to you.

🔒 SECURITY YOU CAN TRUST
- Biometric login (fingerprint) for quick, secure access
- 6-digit login PIN required every time you reopen the app
- Fast BVN-based identity verification to activate your wallet — no selfie or document upload needed
- Bank-grade encrypted connections for every transaction

🛟 SUPPORT WHEN YOU NEED IT
Reach our support team directly via email or WhatsApp from inside the app whenever you have a question or issue.

Download IMAM DATASUB today and take control of your data, bills, and payments — all from one secure wallet.
```
(≈1,750 characters — well within the 4000 limit; trim the sections you don't want to lead with if you want it shorter)

---

## 4. App category & tags

- **Category:** Finance (this is the correct primary category given wallet + bill payment + KYC — do not list under "Tools" or "Communication," Google will likely re-categorize you anyway if mismatched)
- **Tags/keywords to include in your listing where allowed:** data, airtime, VTU, bills, wallet, MTN, Airtel, Glo, 9mobile, DStv, GOtv, electricity, JAMB, WAEC, NECO

---

## 5. Content rating questionnaire — how to answer

Google's content rating form (IARC) asks about violence, sexual content, gambling, drugs, etc. For this app:

| Question | Answer |
|---|---|
| Violence | No |
| Sexual content | No |
| Profanity | No |
| Drugs/alcohol/tobacco references | No |
| Simulated gambling | No |
| **Does the app allow users to purchase digital goods/services with real money?** | **Yes** — data, airtime, bill payments |
| **Does the app share user location?** | No (you request no location permission) |
| **Does the app allow users to interact/communicate?** | No public user-to-user chat exists in your feature list — answer No unless you've added one |

Expected result: this should land in the lowest rating tier (e.g. "Everyone" / "3+"), since there's no violence, sexual content, or gambling — the only notable flag is real-money purchases, which is standard and expected for a fintech app.

---

## 6. Target audience

- Select an **adult target age range** (e.g. 18+) as your primary audience, since:
  - The app requires KYC/BVN verification (financial regulation, not appropriate for minors)
  - It handles real money and wallets
- When Play Console asks "Is your app designed for children?" → **No**

---

## 7. Data Safety form — exact answers

This is the section Google is strictest about matching to actual behavior. Below is a category-by-category breakdown based on what your code actually collects and does (Prisma schema, KYC service, notification service, permissions).

### Does your app collect or share any of the required user data types?
**Yes**

### Personal info
| Data type | Collected? | Shared with 3rd party? | Purpose |
|---|---|---|---|
| Name | Yes | No | Account management, App functionality |
| Email address | Yes | No | Account management, Account creation/login |
| Phone number | Yes | No | Account management, App functionality |
| User IDs | Yes | No | Account management |
| Address | No | — | — |

### Financial info
| Data type | Collected? | Shared with 3rd party? | Purpose |
|---|---|---|---|
| User payment info | Yes (wallet balance, transaction records — **not raw card numbers**, those go directly to your payment processor Paystack) | **Yes** — shared with Paystack for payment processing | App functionality |
| Purchase history | Yes | No | App functionality, Analytics |
| Credit score / other financial info | Yes — BVN-based identity verification (KYC), confirmed to be a pure form: bank + account number + BVN, submitted to `/kyc/verify-bvn`. **No photo, selfie, or document capture is involved anywhere in this flow.** You store only the **last 4 digits** of BVN, never the full number | **Yes** — full BVN is sent to Paystack for verification; you don't store it | App functionality (fraud prevention/security) |

### Photos or videos
**Not collected.** The app no longer includes any photo picker, camera access, or image upload anywhere — profile pictures are a generated initials avatar instead. `CAMERA`, `READ_MEDIA_IMAGES`, `READ_EXTERNAL_STORAGE`, and `WRITE_EXTERNAL_STORAGE` permissions have been removed from the manifest entirely, since nothing in the app used them once the photo picker was removed (receipt downloads use app-private sandboxed storage that needs no permission on any Android version).

### App activity
| Data type | Collected? | Shared? | Purpose |
|---|---|---|---|
| App interactions | Yes (transaction/notification history) | No | App functionality, Analytics |

### Device or other IDs
| Data type | Collected? | Shared? | Purpose |
|---|---|---|---|
| Device or other IDs | Yes — FCM push notification token | **Yes** — shared with Firebase/Google for delivering push notifications | App functionality |

### Location
**Not collected** — you request no location permission anywhere in the manifest.

### Everything else (Health, Messages, Web browsing, etc.)
**Not collected.**

---

### Standard follow-up questions for each data type you marked "Yes" to
Google will ask these for each row above — answer consistently:
- **Is this data processed ephemerally?** → No (you persist it in your database)
- **Is data collection required or optional?** → Required (can't create a functioning wallet account without name/email/phone; KYC is required before certain wallet limits per your `kycStatus` field)
- **Is the data encrypted in transit?** → **Yes** (your API is HTTPS-only now, per the network security config we just locked down)
- **Can users request their data be deleted?** → Yes, if you support account deletion (check `accountStatus: DEACTIVATED/DELETED` in your schema — you already have this) — confirm your in-app account deletion flow actually exists and works before answering Yes here

---

## 8. Financial Services declaration

Since Play Console will likely flag this as a financial app requiring extra review:
- Be ready to state that payment processing (including BVN verification and card transactions) is handled by **Paystack**, a licensed payment processor — you are not directly holding or processing card data yourself.
- Have your Terms & Conditions (already live at `/terms`) and Privacy Policy (`/privacy-policy`) ready — Play Console will link to both.
- If asked whether you provide loans/credit — answer **No** (you're a wallet/bill-payment platform, not a lender).

---

## 9. Contact details for your Play Console listing

- **Support email:** *(confirm/fix the typo above first)*
- **Support phone/WhatsApp:** +234 803 567 9448
- **Privacy Policy URL:** `https://imamdatasubweb-production-4f62.up.railway.app/privacy-policy`
- **Terms of Service URL:** `https://imamdatasubweb-production-4f62.up.railway.app/terms`

---

## Before you submit — final checklist
- [ ] Fix the support email typo (`gmai.com` → confirm correct domain)
- [ ] Confirm your in-app account deletion flow works, if you answer "Yes" to data-deletion requests
- [ ] Have 2–8 screenshots ready (phone-size, no need for tablet unless you support tablets)
- [ ] Feature graphic (1024×500px) for the store listing banner
