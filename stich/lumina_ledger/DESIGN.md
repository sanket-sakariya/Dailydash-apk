# Design System Specification: High-Fidelity Financial Luxury

## 1. Overview & Creative North Star: "The Neon Nocturne"
The Creative North Star for this design system is **The Neon Nocturne**. We are moving away from the "utility app" aesthetic and toward a "luxury dashboard" experience. This system treats financial data not as a chore, but as a high-value digital asset.

The hallmark of this system is **Luminous Depth**. By combining a "True Black" foundation with vibrant, neon-gas accents and glassmorphism, we create a UI that feels like a high-end physical device—think OLED screens and backlit frosted glass. We break the "template" look through intentional asymmetry: transactions aren't just rows; they are floating glass shards with varying weights and glows.

---

## 2. Colors & Luminous Layers
Our palette is rooted in the absence of light (`#0e0e0e`), allowing our Primary Purple and Secondary Cyan to "emit" light rather than just occupy space.

### The Color Tokens
- **Primary (Electric Purple):** `#db90ff` — Used for high-action states and growth indicators.
- **Secondary (Cyan):** `#04c4fe` — Used for secondary data points and steady-state actions.
- **Surface (Deep Charcoal/Black):** `#0e0e0e` to `#262626` — The canvas of the application.

### The "No-Line" Rule
**Explicit Instruction:** Traditional 1px solid borders are strictly prohibited for sectioning. We define boundaries through **Tonal Shifts**. 
- To separate a header from a list, transition the background from `surface` to `surface-container-low`. 
- Content blocks are defined by their elevation in the stack, not by lines that "trap" the data.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of semi-transparent materials.
- **Base Layer:** `surface` (`#0e0e0e`) - The infinite void.
- **Mid Layer:** `surface-container` (`#191919`) - For grouping related data cards.
- **Top Layer:** `surface-container-highest` (`#262626`) - For interactive elements that need to pop.

### The "Glass & Gradient" Rule
Standard flat buttons are insufficient. All primary CTAs must use a **Signature Texture**:
- **Gradient:** Linear 135° from `primary` (`#db90ff`) to `primary-container` (`#d37bff`).
- **Glassmorphism:** For floating overlays, use `surface-variant` at 40% opacity with a `20px` backdrop-blur. This ensures the neon glows from the background "bleed" through the UI, creating a cohesive atmospheric effect.

---

## 3. Typography: Geometric Authority
We utilize **Plus Jakarta Sans** for its modern, premium geometric construction. The hierarchy is designed to feel editorial—large, bold display numbers contrasted with tiny, ultra-refined labels.

- **Display-LG (3.5rem):** For account balances. This is the "Hero" of the screen.
- **Headline-SM (1.5rem):** For section headers (e.g., "Monthly Spending").
- **Title-MD (1.125rem):** For transaction names. Bold and clear.
- **Label-SM (0.6875rem):** For metadata (dates, categories). Use `on-surface-variant` (`#ababab`) to reduce visual noise.

**Editorial Tip:** Use "Title-MD" for the currency symbol and "Display-LG" for the integer to create a sophisticated, staggered typographic rhythm.

---

## 4. Elevation & Depth: Tonal Layering
In this system, "Elevation" is a measure of light, not just shadow.

- **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` background. This creates a "recessed" look that feels organic.
- **Ambient Shadows (The Outer Glow):** For floating action buttons, do not use black shadows. Use a diffused shadow of the accent color (e.g., `primary` at 15% opacity, 30px blur). This mimics the way a neon sign casts light on a dark wall.
- **The "Ghost Border" Fallback:** When a container sits on a background of the same color, use a `1px` stroke of `outline-variant` at **15% opacity**. It should be felt, not seen.
- **Inner Shadows:** Use subtle inner shadows on "input" areas to make them feel carved into the glass surface.

---

## 5. Components

### Floating Action Button (FAB)
- **Shape:** `xl` (3rem/48px+) corner radius.
- **Effect:** Gradient fill (`primary` to `primary-dim`) with a high-intensity `primary` outer glow.
- **Interaction:** On tap, the glow should expand (scale 1.2x) and the blur should intensify.

### Transaction Cards
- **Structure:** Zero borders. Use `surface-container-low` background.
- **Shape:** `md` (1.5rem/24px) corner radius.
- **Spacing:** No dividers. Use `16px` of vertical whitespace between cards to allow the "Deep Dark" background to flow through.
- **Accent:** A 4px vertical "pill" of `secondary` or `primary` on the far left edge to denote the transaction category.

### Input Fields
- **Aesthetic:** Glass-fill. `surface-variant` at 20% opacity.
- **Active State:** The "Ghost Border" becomes 100% opaque `secondary` (Cyan), and a subtle `secondary` glow appears behind the field.

### Sleek Lists (Expense Categories)
- **Leading Element:** Circular icons with a 10% opacity fill of the icon's color, creating a soft "halo" effect around the icon.
- **Trailing Element:** "Headline-SM" typography for the amount, right-aligned to create a strong vertical axis.

---

## 6. Do's and Don'ts

### Do
- **Do** use negative space aggressively. In a dark theme, space is luxury.
- **Do** use `secondary` (Cyan) for positive trends and `error` (`#ff6e84`) for over-budget alerts.
- **Do** experiment with overlapping glass cards (e.g., a card partially covering a background gradient).

### Don't
- **Don't** use pure white (`#ffffff`) for body text; use `on-surface` or `on-surface-variant` to prevent eye strain against the black background.
- **Don't** use standard Material Design "Drop Shadows" (0, 2, 4). They look "muddy" on true black.
- **Don't** use sharp corners. Everything must feel smooth, liquid, and premium (minimum `24px` radius).
- **Don't** use horizontal dividers. If you feel the need for a line, increase the padding instead.