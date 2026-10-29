---
name: order-status-email
description: Compose a customer-facing HTML order status email for Froyo Foundry, with the customer name, order number, an item availability table (requested / in stock / fillable / shortfall), and a prominent coupon code when one was issued. Use whenever an order fulfillment result must be turned into an email body.
---

# Froyo Foundry order status email

Produce a single, self-contained HTML email body that tells a customer exactly
what is happening with their order. Output **only** the HTML document — no
Markdown fences, no commentary before or after it.

## Inputs you need

| Input                          | Required       | Notes                                                                                          |
| ------------------------------ | -------------- | ---------------------------------------------------------------------------------------------- |
| Customer first name            | yes            | Greet by first name. Fall back to "there" if missing.                                          |
| Order number                   | yes            | Show verbatim, e.g. `ORD-2002`.                                                                |
| Line items                     | yes            | Each needs product name, requested qty, available (in stock) qty, fillable qty, shortfall qty. |
| Coupon code + discount percent | only if issued | Omit the whole coupon block when no coupon exists.                                             |
| Alternative recommendations    | optional       | Only include when a shortfall exists.                                                          |

Never invent inventory numbers, product names, or coupon codes. Use only values
supplied by tool output or the order payload. Derive nothing the caller did not
give you except:

- `fillable = min(requested, in stock)`
- `shortfall = requested - fillable`

## Tone

Warm, playful, and brief — this is a frozen yogurt shop, not a bank. Light
dessert wordplay is welcome. Never apologize more than once, and always end on
something positive. Avoid emoji overload: at most two in the whole email.

Subject-line guidance (when the caller needs one):

- Fully fulfilled: `Your Froyo Foundry order {orderId} is good to go!`
- Partial: `A small scoop of news about order {orderId}`
- Nothing available: `We're restocking for order {orderId}`

## Styling rules

Email clients strip `<style>` blocks and ignore flexbox/grid, so:

1. Use **inline `style` attributes only**.
2. Lay out with `<table role="presentation">`, not `<div>` + CSS positioning.
3. Constrain the body to `max-width: 600px` and center it.
4. Use web-safe fonts: `font-family: 'Trebuchet MS', 'Segoe UI', Helvetica, Arial, sans-serif;`
5. Give every `<td>` explicit `padding`; never rely on default spacing.
6. Set `border-collapse: collapse` on data tables and style borders per cell.
7. No external images, web fonts, JavaScript, or background images.

### Brand palette

| Role            | Hex       | Use                                   |
| --------------- | --------- | ------------------------------------- |
| Berry pink      | `#FF5FA2` | Header band, coupon border, headings  |
| Mint            | `#3FD9C4` | Accents, table header row             |
| Cream           | `#FFF8F2` | Page background                       |
| Swirl white     | `#FFFFFF` | Card background                       |
| Deep cocoa      | `#3B2A2F` | Body text                             |
| Shortfall amber | `#B06A00` | Non-zero shortfall numbers            |
| Good green      | `#1F8A4C` | Zero-shortfall / fully filled numbers |

## Required structure

1. **Header band** — berry pink, "Froyo Foundry" wordmark in white.
2. **Greeting** — `Hi {firstName},` plus one sentence of status.
3. **Order number line** — `Order {orderId}` rendered in bold.
4. **Availability table** — columns in this exact order:
   `Flavor | Requested | In stock | We can fill | Shortfall`.
   Right-align numeric columns. Color the shortfall cell amber when it is
   greater than zero and green when it is zero.
5. **Coupon block** — only when a coupon exists. Must be visually dominant:
   dashed berry-pink border, large monospace code, discount percent stated.
6. **Alternatives** — optional bulleted list of in-stock flavors to try.
7. **Footer** — small muted text with a friendly sign-off.

## Reference template

Replace `{{...}}` placeholders, repeat the item row per line item, and delete
the coupon and alternatives blocks entirely when they do not apply.

```html
<!DOCTYPE html>
<html>
  <body style="margin:0; padding:0; background-color:#FFF8F2;">
    <table
      role="presentation"
      width="100%"
      cellpadding="0"
      cellspacing="0"
      style="background-color:#FFF8F2; padding:24px 12px;"
    >
      <tr>
        <td align="center">
          <table
            role="presentation"
            width="600"
            cellpadding="0"
            cellspacing="0"
            style="max-width:600px; width:100%; background-color:#FFFFFF; border-radius:12px; overflow:hidden; font-family:'Trebuchet MS','Segoe UI',Helvetica,Arial,sans-serif; color:#3B2A2F;"
          >
            <tr>
              <td
                style="background-color:#FF5FA2; padding:20px 24px; color:#FFFFFF; font-size:22px; font-weight:bold; letter-spacing:0.5px;"
              >
                Froyo Foundry
              </td>
            </tr>

            <tr>
              <td style="padding:24px 24px 8px 24px;">
                <p style="margin:0 0 12px 0; font-size:18px;">
                  Hi {{firstName}},
                </p>
                <p style="margin:0 0 12px 0; font-size:15px; line-height:22px;">
                  {{statusSentence}}
                </p>
                <p style="margin:0 0 4px 0; font-size:15px;">
                  Order <strong style="color:#FF5FA2;">{{orderId}}</strong>
                </p>
              </td>
            </tr>

            <tr>
              <td style="padding:8px 24px 16px 24px;">
                <table
                  role="presentation"
                  width="100%"
                  cellpadding="0"
                  cellspacing="0"
                  style="border-collapse:collapse; font-size:14px;"
                >
                  <tr style="background-color:#3FD9C4; color:#1A3C38;">
                    <th
                      align="left"
                      style="padding:10px 12px; border:1px solid #BEEFE8;"
                    >
                      Flavor
                    </th>
                    <th
                      align="right"
                      style="padding:10px 12px; border:1px solid #BEEFE8;"
                    >
                      Requested
                    </th>
                    <th
                      align="right"
                      style="padding:10px 12px; border:1px solid #BEEFE8;"
                    >
                      In stock
                    </th>
                    <th
                      align="right"
                      style="padding:10px 12px; border:1px solid #BEEFE8;"
                    >
                      We can fill
                    </th>
                    <th
                      align="right"
                      style="padding:10px 12px; border:1px solid #BEEFE8;"
                    >
                      Shortfall
                    </th>
                  </tr>
                  <!-- repeat one row per line item -->
                  <tr>
                    <td
                      align="left"
                      style="padding:10px 12px; border:1px solid #EFE2DA;"
                    >
                      {{productName}}
                    </td>
                    <td
                      align="right"
                      style="padding:10px 12px; border:1px solid #EFE2DA;"
                    >
                      {{requestedQty}}
                    </td>
                    <td
                      align="right"
                      style="padding:10px 12px; border:1px solid #EFE2DA;"
                    >
                      {{availableQty}}
                    </td>
                    <td
                      align="right"
                      style="padding:10px 12px; border:1px solid #EFE2DA;"
                    >
                      {{fillableQty}}
                    </td>
                    <td
                      align="right"
                      style="padding:10px 12px; border:1px solid #EFE2DA; color:{{#1F8A4C when 0, #B06A00 when > 0}}; font-weight:bold;"
                    >
                      {{shortfallQty}}
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

            <!-- coupon block: include ONLY when a coupon was issued -->
            <tr>
              <td style="padding:8px 24px 16px 24px;">
                <table
                  role="presentation"
                  width="100%"
                  cellpadding="0"
                  cellspacing="0"
                  style="border:3px dashed #FF5FA2; border-radius:12px; background-color:#FFF0F6;"
                >
                  <tr>
                    <td align="center" style="padding:18px 16px;">
                      <p
                        style="margin:0 0 6px 0; font-size:14px; text-transform:uppercase; letter-spacing:1px; color:#B2185E;"
                      >
                        Here's {{discountPercent}}% off your next tub
                      </p>
                      <p
                        style="margin:0 0 6px 0; font-family:'Courier New',Courier,monospace; font-size:28px; font-weight:bold; color:#FF5FA2;"
                      >
                        {{couponCode}}
                      </p>
                      <p style="margin:0; font-size:12px; color:#7A5A63;">
                        Use it at checkout — our way of saying thanks for your
                        patience.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

            <!-- alternatives block: include ONLY when there is a shortfall -->
            <tr>
              <td
                style="padding:0 24px 16px 24px; font-size:14px; line-height:22px;"
              >
                <p style="margin:0 0 6px 0; font-weight:bold; color:#FF5FA2;">
                  Scooped and ready right now
                </p>
                <ul style="margin:0; padding-left:20px;">
                  <li style="margin-bottom:4px;">
                    {{altProductName}} — {{altDescription}}
                  </li>
                </ul>
              </td>
            </tr>

            <tr>
              <td
                style="padding:16px 24px 24px 24px; border-top:1px solid #F2E4DC; font-size:12px; color:#8A7279;"
              >
                Stay swirly,<br />The Froyo Foundry crew
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
```

## Before you send

- [ ] Customer first name and order number both appear.
- [ ] Every ordered line item has exactly one table row.
- [ ] `fillable` and `shortfall` math is consistent with requested and in-stock.
- [ ] Coupon block present if and only if a coupon code was issued.
- [ ] No `<style>` tags, external assets, or scripts remain.
- [ ] Output is raw HTML only, with no Markdown code fences.
