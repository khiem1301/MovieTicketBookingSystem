---
name: Cinematic Immersive
colors:
  surface: '#200e0c'
  surface-dim: '#200e0c'
  surface-bright: '#4a3330'
  surface-container-lowest: '#1a0908'
  surface-container-low: '#2a1614'
  surface-container: '#2e1a18'
  surface-container-high: '#3a2522'
  surface-container-highest: '#462f2c'
  on-surface: '#ffdad5'
  on-surface-variant: '#e9bcb6'
  inverse-surface: '#ffdad5'
  inverse-on-surface: '#412b28'
  outline: '#af8782'
  outline-variant: '#5e3f3b'
  surface-tint: '#ffb4aa'
  primary: '#ffb4aa'
  on-primary: '#690003'
  primary-container: '#e50914'
  on-primary-container: '#fff7f6'
  inverse-primary: '#c0000c'
  secondary: '#ffb4a5'
  on-secondary: '#650b00'
  secondary-container: '#c31e00'
  on-secondary-container: '#ffd7d0'
  tertiary: '#a7c8ff'
  on-tertiary: '#003061'
  tertiary-container: '#0072d7'
  on-tertiary-container: '#f8f9ff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad5'
  primary-fixed-dim: '#ffb4aa'
  on-primary-fixed: '#410001'
  on-primary-fixed-variant: '#930007'
  secondary-fixed: '#ffdad3'
  secondary-fixed-dim: '#ffb4a5'
  on-secondary-fixed: '#3e0400'
  on-secondary-fixed-variant: '#8e1300'
  tertiary-fixed: '#d5e3ff'
  tertiary-fixed-dim: '#a7c8ff'
  on-tertiary-fixed: '#001b3c'
  on-tertiary-fixed-variant: '#004689'
  background: '#200e0c'
  on-background: '#ffdad5'
  surface-variant: '#462f2c'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
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
    lineHeight: '1.5'
  label-lg:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.05em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-max-width: 1200px
  auth-card-width: 480px
  gutter: 24px
  margin-page: 64px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 40px
---

## Brand & Style
This design system captures the dramatic allure of a premier cinema experience. The brand personality is bold, high-end, and deeply immersive, designed to evoke the excitement of the opening credits. 

The aesthetic is a sophisticated blend of **Modern Corporate** and **Glassmorphism**. It utilizes deep obsidian surfaces contrasted against vibrant, glowing accents to create a sense of depth and hierarchy. The visual language focuses on high-contrast storytelling, ensuring that the authentication process feels like a VIP entry into a premium digital theater. High-quality background imagery (movie stills or abstract lighting) should be used with heavy "stage-lighting" vignettes to draw the user’s focus entirely toward the central interaction modules.

## Colors
The palette is built on a "Pitch Black" foundation to maximize OLED contrast and visual impact. 

- **Primary (Cinema Red):** Used for the most critical actions, such as "Sign In" or "Create Account." It represents the classic velvet curtain and theatrical branding.
- **Secondary (Orange-Red):** Employed primarily for hover states and subtle gradients to add heat and energy to the primary red.
- **Neutrals:** The background uses a pure black (#0A0A0A), while UI surfaces utilize a slightly elevated Charcoal (#1A1A1A) to provide separation without losing the dark aesthetic.
- **Functional Colors:** Success and Error states are saturated but balanced to remain legible against dark backgrounds, ensuring user feedback is immediate and unmistakable.

## Typography
The typography system prioritizes high-impact legibility and a modern, technical feel. 

**Geist** is used for all display and headline roles to provide a sharp, monospaced-influenced precision that feels like modern cinema tech. **Inter** handles the body and instructional text, ensuring that even in low-light environments, form labels and error messages remain crystal clear. 

Headlines should utilize tight letter spacing and heavy weights to command attention, while labels utilize increased tracking and uppercase styling to provide a structural, "meta-data" feel characteristic of film production slates.

## Layout & Spacing
This design system is optimized exclusively for desktop and laptop viewports. It employs a **Fixed Grid** philosophy for the core authentication experience.

The primary interaction takes place within a centralized "Glass Container" with a fixed width of 480px. This ensures that the user's focus is never diluted by the expansive screen size. Spacing follows a strict 8px linear scale. Vertical rhythm is maintained through three primary "stack" tokens: 12px for related elements (label to input), 24px for standard component separation, and 40px for major section breaks (header to form). 

Background content should be fixed or use a subtle parallax effect, while the central card remains anchored in the absolute center of the viewport.

## Elevation & Depth
Depth is created through **Glassmorphism** and concentrated light sources. 

The main authentication card uses a semi-transparent background (`rgba(26, 26, 26, 0.6)`) with a high-density `backdrop-filter: blur(20px)`. To define the edges, a thin 1px border is applied with a linear gradient (top-left to bottom-right) using a low-opacity white to a low-opacity charcoal.

**Shadows:**
Instead of traditional drop shadows, this design system uses "Ambient Glows." Shadows should have a large spread (40px+) with low opacity (`0.4`) and a subtle tint of Cinema Red (#E50914) to suggest the card is being backlit by a neon source or a theater screen.

## Shapes
The shape language is sophisticated and approachable, moving away from aggressive sharp corners to reflect a premium, modern software feel.

The base unit for roundedness is **16px (1rem)**. This is applied to all primary containers and buttons. Input fields and smaller interactive elements use a standard **8px (0.5rem)** radius. Large "Hero" cards or background panels may scale up to **24px (1.5rem)** to emphasize their role as primary containers. This consistency in curvature ensures the UI feels cohesive and high-end.

## Components
Consistent component styling is vital for maintaining the cinematic atmosphere:

- **Buttons:** Primary buttons use a solid Cinema Red to Orange-Red gradient. They should feature a subtle inner-glow on hover to simulate a backlit physical button.
- **Input Fields:** Styled with a "Dark Inset" look. The background is a solid #0A0A0A with a 1px border. On focus, the border transitions to Cinema Red with a soft 4px outer glow.
- **Glass Cards:** The central container for all auth flows. Must include the backdrop blur and gradient border defined in the Elevation section.
- **Chips / Tags:** Used for selecting genres or preferences during onboarding. These should be outlined with high-contrast text and a semi-transparent fill that becomes solid Cinema Red when selected.
- **Checkboxes & Radios:** Custom-styled to match the brand. Use Cinema Red for the "checked" state with a white checkmark icon. Avoid default browser styling.
- **Progress Indicators:** Use a thin, high-glow red line at the top of the glass container to indicate multi-step authentication or loading states.