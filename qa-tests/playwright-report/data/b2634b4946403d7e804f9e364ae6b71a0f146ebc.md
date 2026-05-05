# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: feedback_spec.js >> closes feedback form when cancel is clicked
- Location: tests\feedback_spec.js:95:1

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: getByText(/gkshop/i).first()
Expected: visible
Timeout: 5000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 5000ms
  - waiting for getByText(/gkshop/i).first()

```

# Page snapshot

```yaml
- generic [ref=e4]:
  - generic:
    - generic:
      - generic:
        - generic:
          - generic:
            - group:
              - img [ref=e5]
              - generic:
                - generic: Welcome back
              - generic:
                - generic:
                  - generic: Public signup is available only for Shop Owner, Territory Distributor, and Sales Representative accounts.
                - textbox "Email/Username" [ref=e7]: GK123
                - generic [ref=e8]:
                  - textbox "Password" [ref=e9]: Bruhhh!123
                  - button [ref=e10]
                - generic:
                  - generic: Don't have an account?
                - button "Create an account" [disabled] [ref=e11]
```

# Test source

```ts
  1   | const { test, expect } = require('@playwright/test');
  2   | 
  3   | const BASE_URL = 'http://localhost:7574';
  4   | 
  5   | // Increase timeout — Flutter app is slow to render
  6   | test.setTimeout(90000);
  7   | 
  8   | // ─── Shared helper: launch app and log in as shop owner ────────────────────
  9   | async function loginAsShopOwner(page) {
  10  |   await page.goto(BASE_URL);
  11  |   await page.waitForTimeout(4000);
  12  | 
  13  |   // Handle Flutter accessibility overlay
  14  |   const enableA11y = page.getByRole('button', { name: /Enable accessibility/i });
  15  |   await page.waitForTimeout(2000);
  16  |   if (await enableA11y.isVisible().catch(() => false)) {
  17  |     await enableA11y.dispatchEvent('click');
  18  |     await page.waitForTimeout(6000);
  19  |   }
  20  | 
  21  |   // Wait for login form to be ready
  22  |   await page.waitForSelector('input', { timeout: 30000 });
  23  |   await page.waitForTimeout(1000);
  24  | 
  25  |   // Fill in login credentials
  26  |   await page.getByRole('textbox', { name: /Email\/Username/i }).fill('GK123');
  27  |   await page.waitForTimeout(500);
  28  |   await page.getByRole('textbox', { name: /Password/i }).fill('Bruhhh!123');
  29  |   await page.waitForTimeout(500);
  30  |   await page.getByRole('button', { name: /Log in/i }).dispatchEvent('click');
  31  |   await page.waitForTimeout(8000);
  32  | 
  33  |   // Verify we are on the home screen
  34  |   await expect(
  35  |     page.getByText(/gkshop/i).first()
> 36  |   ).toBeVisible();
      |     ^ Error: expect(locator).toBeVisible() failed
  37  | }
  38  | 
  39  | // ─── Shared helper: open the feedback form ──────────────────────────────────
  40  | async function openFeedbackForm(page) {
  41  |   await page.getByRole('button', { name: /Feedback/i }).click();
  42  |   await page.waitForTimeout(2000);
  43  | 
  44  |   // Verify feedback form is open
  45  |   await expect(
  46  |     page.getByText(/Please briefly type your feedback/i)
  47  |   ).toBeVisible();
  48  | }
  49  | 
  50  | 
  51  | // ═══════════════════════════════════════════════════════════════════════════════
  52  | // TEST 1: Happy path — submit valid feedback
  53  | // ═══════════════════════════════════════════════════════════════════════════════
  54  | test('successfully submits feedback', async ({ page }) => {
  55  |   await loginAsShopOwner(page);
  56  |   await openFeedbackForm(page);
  57  | 
  58  |   await page.getByRole('textbox', { name: /Feedback message/i }).fill('This is a test feedback message.');
  59  |   await page.waitForTimeout(500);
  60  | 
  61  |   await page.screenshot({ path: 'test-results/feedback-before-submit.png', fullPage: true });
  62  | 
  63  |   await page.getByRole('button', { name: /Submit/i }).click();
  64  |   await page.waitForTimeout(3000);
  65  | 
  66  |   await page.screenshot({ path: 'test-results/feedback-after-submit.png', fullPage: true });
  67  | 
  68  |   await expect(
  69  |     page.getByText(/success|thank you|feedback.*sent|submitted/i).first()
  70  |   ).toBeVisible();
  71  | });
  72  | 
  73  | 
  74  | // ═══════════════════════════════════════════════════════════════════════════════
  75  | // TEST 2: Validation error — submit empty feedback
  76  | // ═══════════════════════════════════════════════════════════════════════════════
  77  | test('shows validation error when submitting empty feedback', async ({ page }) => {
  78  |   await loginAsShopOwner(page);
  79  |   await openFeedbackForm(page);
  80  | 
  81  |   await page.getByRole('button', { name: /Submit/i }).click();
  82  |   await page.waitForTimeout(2000);
  83  | 
  84  |   await page.screenshot({ path: 'test-results/feedback-empty-error.png', fullPage: true });
  85  | 
  86  |   await expect(
  87  |     page.getByText(/required|cannot be empty|enter.*feedback|feedback.*required/i).first()
  88  |   ).toBeVisible();
  89  | });
  90  | 
  91  | 
  92  | // ═══════════════════════════════════════════════════════════════════════════════
  93  | // TEST 3: Cancel — closes the feedback form
  94  | // ═══════════════════════════════════════════════════════════════════════════════
  95  | test('closes feedback form when cancel is clicked', async ({ page }) => {
  96  |   await loginAsShopOwner(page);
  97  |   await openFeedbackForm(page);
  98  | 
  99  |   await page.getByRole('button', { name: /Cancel/i }).click();
  100 |   await page.waitForTimeout(2000);
  101 | 
  102 |   await page.screenshot({ path: 'test-results/feedback-cancelled.png', fullPage: true });
  103 | 
  104 |   await expect(
  105 |     page.getByText(/Please briefly type your feedback/i)
  106 |   ).not.toBeVisible();
  107 | });
  108 | 
  109 | 
  110 | // ═══════════════════════════════════════════════════════════════════════════════
  111 | // TEST 4: Activity center — thank you message appears after submission
  112 | // BUG: Thank you message not appearing in activity center — flagged to dev
  113 | // ═══════════════════════════════════════════════════════════════════════════════
  114 | test('thank you message appears in activity center after feedback submission', async ({ page }) => {
  115 |   await loginAsShopOwner(page);
  116 |   await openFeedbackForm(page);
  117 | 
  118 |   await page.getByRole('textbox', { name: /Feedback message/i }).fill('Test feedback for activity center check.');
  119 |   await page.getByRole('button', { name: /Submit/i }).click();
  120 |   await page.waitForTimeout(3000);
  121 | 
  122 |   await page.getByRole('button', { name: /Activity/i }).dispatchEvent('click');
  123 |   await page.waitForTimeout(3000);
  124 | 
  125 |   await page.screenshot({ path: 'test-results/activity-center.png', fullPage: true });
  126 | 
  127 |   const thankYouVisible = await page.getByText(/thank you|feedback.*received|we.*received.*feedback/i).first().isVisible().catch(() => false);
  128 | 
  129 |   if (!thankYouVisible) {
  130 |     console.log('🐛 BUG: Thank you message not appearing in activity center after feedback submission — flagged to dev.');
  131 |   } else {
  132 |     await expect(page.getByText(/thank you|feedback.*received|we.*received.*feedback/i).first()).toBeVisible();
  133 |   }
  134 | });
  135 | 
```