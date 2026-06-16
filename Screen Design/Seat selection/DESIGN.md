---
name: Cinematic Premium
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#e9bcb6'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#af8782'
  outline-variant: '#5e3f3b'
  surface-tint: '#ffb4aa'
  primary: '#ffb4aa'
  on-primary: '#690003'
  primary-container: '#e50914'
  on-primary-container: '#fff7f6'
  inverse-primary: '#c0000c'
  secondary: '#e9c349'
  on-secondary: '#3c2f00'
  secondary-container: '#af8d11'
  on-secondary-container: '#342800'
  tertiary: '#c8c6c5'
  on-tertiary: '#303030'
  tertiary-container: '#737272'
  on-tertiary-container: '#fbf8f8'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad5'
  primary-fixed-dim: '#ffb4aa'
  on-primary-fixed: '#410001'
  on-primary-fixed-variant: '#930007'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1b1b1c'
  on-tertiary-fixed-variant: '#474746'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 64px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-sm:
    fontFamily: Montserrat
    fontSize: 40px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.3'
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.2'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding-desktop: 80px
  container-padding-mobile: 20px
  gutter: 24px
  section-gap: 64px
---

## Brand & Style

The design system is engineered to evoke the immersive, high-stakes atmosphere of a premium theater lobby. It centers on a **Cinematic Glassmorphism** aesthetic, utilizing deep layers, blurred backdrops, and vibrant light-leaks to simulate the experience of a projector in a dark room.

The brand personality is authoritative yet welcoming, focusing on high-fidelity visuals and effortless transitions. The target audience expects a luxury "Red Carpet" experience from discovery to checkout. We utilize high-contrast accents against a monochromatic dark base to ensure the content (movie posters and trailers) remains the protagonist of the interface.

## Colors

The palette is rooted in the "Dark Room" philosophy. The background uses a tiered approach: `#0B0B0B` for the deepest canvas and `#121212` for primary surfaces. 

- **Cinematic Red (#E50914):** Reserved strictly for primary actions (Book Now, Play, Confirm) and critical status indicators.
- **VIP Gold (#D4AF37):** Used exclusively for premium tiers, loyalty rewards, and "IMAX" or "Gold Class" labels.
- **Glass Overlays:** Semi-transparent whites (5-10% opacity) with a 20px-40px background blur are used to create depth without breaking the dark aesthetic.

## Typography

This design system utilizes a dual-font strategy to balance impact with utility. 

**Montserrat** is the voice of the brand—used for headlines and display text to provide a bold, geometric, and modern cinematic feel. **Inter** handles all functional data, body copy, and labels, providing exceptional legibility during the seat selection and checkout processes. Use "All Caps" with increased letter spacing for labels (`label-md`) to denote category headers or movie genres.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a maximum content width of 1440px for desktop to maintain optical comfort.

- **Desktop:** 12-column grid, 24px gutters, 80px side margins.
- **Tablet:** 8-column grid, 20px gutters, 40px side margins.
- **Mobile:** 4-column grid, 16px gutters, 20px side margins.

Horizontal scrolling "shelves" are the preferred layout pattern for movie categories (e.g., "Trending Now"), allowing users to browse vast amounts of content without excessive vertical scrolling.

## Elevation & Depth

Visual hierarchy is achieved through **Glassmorphism** and **Tonal Layering**. 

1. **Floor (Level 0):** `#0B0B0B` - The main background.
2. **Surface (Level 1):** `#121212` - Base cards and navigation bars.
3. **Glass (Level 2):** Semi-transparent surfaces with `backdrop-filter: blur(24px)`. Used for modals, dropdowns, and floating widgets.
4. **Glow (Level 3):** Subtle, colored drop shadows (e.g., 20% opacity of the primary red) used behind movie cards on hover to create a "backlit" effect.

Shadows should be soft and diffused (spread 10px-30px) rather than sharp or directional.

## Shapes

The shape language is sophisticated and approachable. A standard radius of `0.75rem (12px)` is applied to cards and input fields, while buttons and featured movie posters use `1rem (16px)` to feel more prominent.

Buttons are never fully pill-shaped (except for the AI chatbot) to maintain the structural, architectural integrity of the "Modern Corporate" influence.

## Components

### Movie Cards
Cards should feature a 2:3 aspect ratio poster. On hover, the card scales by 1.05x, intensifies its inner glow, and reveals a "Quick Book" glassmorphic overlay.

### Navigation
The top navigation bar is a fixed glassmorphic element. Search should expand into a full-screen blurred overlay to keep focus on discovery.

### Date & Time Selectors
Use a horizontal scrolling date picker. Selected states use a Primary Red background with white text. Times are displayed as outlined chips that "fill" with the primary color upon selection.

### AI Chatbot Widget
A floating circular button (Pill-shaped) in the bottom right. It uses a high-density glass effect with a subtle VIP Gold border to signify its "Concierge" status.

### Buttons
- **Primary:** Solid Red, White text, Bold Montserrat.
- **Secondary:** Transparent with a 1px White border (30% opacity).
- **VIP:** Solid Gold, Black text.