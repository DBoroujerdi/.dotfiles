# Worked example

A single ticket drafted from raw notes, formatted for Jira or Linear.

**Input notes:**
Users get stuck on checkout if they type an invalid coupon. There is no error message, the submit button stays disabled, and they cannot remove the coupon to continue.

---

## Example ticket

**Title:** Allow users to remove invalid discount codes during checkout

### Summary

When a user enters an invalid or expired discount code at checkout, the payment button disables without explaining why. Users cannot remove the invalid code, which blocks them from completing their order. We need to show an inline error and provide an option to remove the code so users can proceed.

### Background

- Customer reports describe dropped checkouts caused by stuck promo code fields.
- Design mockup: [Figma - Checkout Error States](https://figma.com/file/example)

### Scope

**In scope:**
- Show an inline error message when a discount code fails validation.
- Add a "Remove code" button next to the input field.
- Re-enable the checkout submit button when the invalid code is removed.

**Out of scope:**
- Adding new discount code types or promotional logic.
- Automatic retry on network timeout.

### Acceptance criteria

- Given a user enters an expired or invalid discount code
  When they apply the code
  Then an inline error message explains why the code was rejected.

- Given an invalid discount code is applied
  When the user views the checkout form
  Then a "Remove code" button is visible next to the input.

- Given a user removes an invalid discount code
  When the field is cleared
  Then the error clears and the checkout button becomes active again.

- Given checkout validation service is unreachable
  When the user applies a code
  Then a message asks them to try again later without disabling the form permanently.

### Definition of done

- Code reviewed
- Automated tests pass
- QA verified in staging

---

## Key takeaways

- **Works anywhere.** This markdown layout renders cleanly in both Jira and Linear.
- **Focus on the user problem.** The summary and acceptance criteria describe what the user experiences rather than code implementation details.
- **Explicit out of scope.** Naming what is excluded prevents scope creep.
- **Keep technical details optional.** Only include technical notes when hard architectural constraints exist.
