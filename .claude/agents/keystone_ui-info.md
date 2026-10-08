---
name: keystone_ui-info
description: Use to learn what Keystone UI offers — what the component system covers, its layout, color and theme model, and the vocabulary the install and develop locals assume.
tools: Read
scope: UI — pages, forms, tables, navigation, dashboards
---

This local explains Keystone UI and sends you to the local that does the work.
It changes nothing and gives no steps.

## What Keystone UI is

Keystone UI is a Rails engine gem that supplies a host app's visual layer as a
library of view helpers built on ViewComponent. Screens are built from named
pieces — page shells, sections, panels, grids, form fields, data tables,
navigation bars, breadcrumbs, cards, stat tiles, charts, funnels, goal buckets, pipelines,
banners, the calculation behind a figure, a breakdown of amounts and their
total, a figure coloured as a gain or a loss, an info button — instead of hand-written ERB and
Tailwind. Every class the UI renders lives inside the gem, in frozen constants,
so the look is defined in one place.

Reach for it whenever you build or change a screen in an app that has it
installed. It exists to stop UI drift: two pages built from the same helpers
cannot disagree about spacing, color or dark-mode treatment, and a change to a
component updates every page that uses it. It is mobile-first — components ship
separate mobile and desktop treatments (a bottom tab bar and mobile header on
small screens, a full navigation bar from the `lg:` breakpoint up), because
these apps are often viewed in a native webview. The form and show page shells
follow the same split for going back: the mobile header carries the back arrow on
small screens, and from `lg:` up the shell shows a "Back" link. Given a trail of
earlier pages, the shell shows breadcrumbs under that "Back" link, ending with
the page's own title. A page that passes no trail gets the one the app or
another gem supplies for the request, if any, and a page that passes no back
link goes back to that trail's last link. A trail or back link the page passes
itself always wins. Supplying a trail is set up through the install local.

A nav tab's own page has nowhere to go back to, and it says so by passing an
empty trail. Such a page shows no "Back" link and no breadcrumbs, and its mobile
header shows no back arrow. Every other form and show page must end up with a
Back link. A page with no back link, no trail and no supplied trail raises
`KeystoneUi::MissingBackLink` when it renders, and the message names the page's
title and says an empty trail marks a nav tab's page. A trail with a link
missing its label or its address raises `KeystoneUi::IncompleteTrail`, also
naming the page. The "Back" link, the breadcrumbs and the form page's title
appear at the top of the page container, inside its width and padding, so a
page using either shell also uses the page container.

## Interface

This local declares no commands. The two working surfaces belong elsewhere:

- **Getting the gem into a host app** — adding it, wiring Tailwind, Stimulus and
  the theme attributes on the layout, setting the palette, and the suppliers
  for trails, themes, looks and saved table layouts → **`keystone_ui-install`**.
- **Building UI with it** — which helper renders what, what keywords it takes,
  how helpers nest → **`keystone_ui-develop`**.

## How to use it

One decision: is Keystone UI already set up in the app?

- No, or the setup is out of date → **`keystone_ui-install`**.
- Yes, and you have a screen to build or edit → **`keystone_ui-develop`**. Do not
  hand-write ERB or Tailwind for UI it covers.

Questions about which piece fits a scenario also go to the develop local, which
holds the catalog.

## Conventions

- **Helpers, not classes.** Every piece of UI is a view helper prefixed `ui_`,
  called from ERB. The one layout helper that is not prefixed `ui_` writes the
  theme onto the page's `html` tag, and it belongs to the install local.
  Components live under the `Keystone::Ui` namespace, but a host app does not
  name a component class directly. The one exception is the table column value
  object, which is passed as an argument and renders nothing.
- **Containers take blocks, leaves take keywords.** Helpers that wrap content
  (page shells, sections, panels, grids, forms, tables) yield a block. Helpers
  that render one thing (a button, a badge, a field, a stat, a bucket) are
  configured entirely by keyword arguments. The navigation bar exposes named
  slots instead of a single block.
- **Action menus.** An action menu is an ellipsis button that opens a dropdown
  of actions, shown at every screen size. The mobile action menu is the one
  hidden from `lg:` up. Each action is a label, an address and an HTTP method.
  A plain visit renders as a link. Any other method renders as a button that
  sends that method, so an action that changes data is never a bare link. An
  action can carry a question that Turbo asks before it runs. A delete asks
  "<label> this? This cannot be undone." unless it is given its own question,
  and other actions ask nothing unless given one. A data table puts each row's actions in one action menu at the end of the row,
  and a section can carry an action menu in its header beside its title.
- **Info panels.** A stat card, a radio card and a checkbox row can each carry
  extra text about themselves. Given that text, the piece shows an info button,
  and the text stays hidden until the button is hovered or tapped. A piece
  given no such text shows no button. On a radio card and a checkbox row the
  button sits on the line with the label. Wherever it is placed, the button
  sits level with the text beside it.
- **Standalone info button.** The same info button can be placed on its own,
  beside anything. It takes a short summary, which is required, and shows it
  when the button is hovered. Given nothing more, a tap shows the summary too.
  Given a block of further detail, a tap opens that detail instead, in a panel
  under the button, and the summary stays the hover text. Both popups are
  placed against the screen, not against the element the button sits in, so a
  table or any other container that clips its contents does not cut them off.
  Each opens under the button with its right edge on the button's, the first
  time as well as every later time, and is kept on the screen when the button
  is near the left edge. The detail panel is wider than the summary. Both carry
  one shared popup class from keystone_ui-styles, which decides how their text
  wraps and how they fit a narrow screen. A second tap closes
  what the first opened, a click anywhere else closes the detail, and
  scrolling the page closes both.
- **A breakdown is text.** A breakdown lists amounts, each beside a label
  saying what it is, and ends with a total set apart from the lines above it.
  Every line and the total are an amount and a label, passed as
  already-formatted text and shown as written. The component adds nothing up,
  so the total is whatever it is given. Its whole layout comes from
  keystone_ui-styles' `ks-breakdown` classes: how the amounts and labels line
  up, and how the total is set apart. The component sets no widths or spacing
  of its own, so a breakdown looks right only with a keystone_ui-styles version
  that defines those classes. It has no button and no hidden state of
  its own, and it can be placed inside an info button's detail.
- **A toned figure is text.** A figure shows one amount inline, in plain text
  or in the success or danger colour, so it reads as a gain or a loss without a
  badge around it. The amount is passed as already-formatted text and shown as
  written, and the tone is chosen by name. An unknown tone raises at render
  time. The colours come from keystone_ui-styles, so a figure shows its tone
  only with a keystone_ui-styles version that defines those classes.
- **The last table column is right-aligned.** In a data table with no actions
  column, the last column's header is right-aligned like the cells beneath it,
  so a figure or total placed in that header lines up with the figures below.
- **A locked first column.** A table column can be marked locked. When it is
  the table's first column, its header and cells stay in view while the rest
  of the table scrolls sideways, styled by keystone_ui-styles' locked header
  and cell classes. A locked column anywhere else renders as an ordinary
  column. A locked column cannot be hidden or moved, so it never appears in the
  "Columns" menu and a saved layout leaves it where it is, even when it is also
  marked hideable.
- **Saved table layouts.** A data table can be given a key naming it. A table
  with a key asks the app, or another gem such as keystone_ui-preferences, for
  the layout saved under that key for the request. A saved layout lists the
  columns to hide, and only columns marked hideable can be hidden. The columns
  the table's own call hides are its default layout. A saved layout that lists
  columns to hide replaces that default, and a saved empty list shows every
  column. When nothing is saved, or the saved layout lists no columns to hide,
  the table keeps its default. A saved layout can also list an order for the
  columns. Only hideable columns move: they fill the places hideable columns
  held in the table's own call, in the saved order, and any the order leaves
  out follow the ones it names. Every other column keeps its place, and a
  layout with no order keeps the order the columns were declared in. When the
  supplier gives an address to save to, a "Columns" menu appears above the
  table, at its right, and saves the user's choice there, even before anything
  has been saved. The menu lists the hideable columns in the order the table
  shows them, each with a box to show or hide it and buttons to move it up or
  down. The menu and the table read the same saved layout, so the menu's
  ticked boxes and order always match the columns the table shows. An unticked column's name is greyed at once. Ticking boxes and moving
  columns sends nothing while the menu is open. Closing the menu, with its
  Columns button or by clicking anywhere outside it, saves the hidden columns
  and the order together once, then reloads the page. Closing it with nothing
  changed saves nothing. When the save is refused or cannot reach the server,
  the page does not reload. The Columns menu shows the message "Your
  column changes were not saved." and puts its boxes and order back to what
  the table shows.
  A table with no key, or an app with no supplier, renders from its own call
  alone. Setting up the supplier belongs to the install local.
- **Suggestions.** A form field can carry a list of suggested values. The
  browser offers them while the field's text is typed, and the user can still
  enter a value that is not on the list. This applies to a field with a typed
  input, such as text, number, email, password or date. A textarea, select or
  checkbox field ignores the list, and a field given no list offers nothing.
  It needs no JavaScript.
- **Options are symbols, and each component accepts its own set.** Appearance is
  chosen by name — `variant:`, `size:`, `type:`, `padding:`, `spacing:`,
  `max_width:`, `radius:` — on a size scale (`:sm` … `:xl`) or a short list of
  named choices. A button's `variant:` and a badge's `variant:` accept
  different symbols, and the develop local carries the real values. Most
  components raise on a symbol they do not know, so a wrong guess fails at
  render time.
- **Measured values are numbers.** Components that measure or compare values, such as
  progress bars, funnels and buckets, do arithmetic on them. Pass a number, not
  a formatted string such as `"9,000"`. A bucket raises on one.
- **A funnel has two shapes.** Both size each step against the first step and
  show the percent carried from one step to the next. The default draws one bar
  per step, each with its label and value on a row above it. The joined shape
  draws the steps as one figure: each step's value and label sit in a column on
  the left, each step is a block centred at its width, and a neutral band
  between two blocks narrows from one width to the next and holds the percent.
  Any other shape raises `ArgumentError`. Neither shape needs JavaScript.
- **A line chart is labelled or dated.** A line chart draws one line per
  series, and each series is a name and its values, with an optional colour
  and an optional dashed line. Its horizontal axis is given one of two ways,
  never both and never neither, and the wrong combination raises
  `ArgumentError`. Labels are text, one per value, spaced evenly and shown as
  written. Dates are one day per value, and a dated chart places each point by
  its day, so a gap of a week is seven times as wide as a gap of a day. A dated
  axis runs from the first day to the last, marks only whole days, and reads
  each day as a date such as "Oct 2, 2026", which is also what a hovered point
  shows. A time of day is dropped, so a dated chart has one position per day.
- **A calculation is text.** The calculation behind a figure is the opposite
  case. It is a list of groups, each with an optional title and its lines, and
  each line is a label, the working and the result. They are passed as
  already-formatted text and shown as written. The component does no
  arithmetic, and it is closed by default under a quiet summary row.
- **Semantic color, not literal color.** The themed hue is `accent-*` and the
  themed neutral family is `surface-*`, both CSS custom properties whose
  defaults (blue and zinc) come from the keystone_ui-styles gem. Retheming an
  app changes those values, not the components. Some components still use
  Tailwind's stock `gray-*` and `zinc-*` neutrals, or fixed status colors such
  as green and amber, directly. Changing the defaults belongs to the install
  local.
- **Looks.** A look is one CSS file that sets the `--ks-` variables from
  keystone_ui-styles 0.6.0 or later: corner radius, font, label weight, border
  width, padding and colours. Each colour variable has a `-dark` partner read
  on a dark page. Buttons, panels, cards, alerts, badges, form fields, the
  modal, the action menu, the mobile action menu, the column picker, multi select, copy button,
  theme toggle, checkbox row, radio card, option card, file upload and colour
  picker read these variables. So do the data display components: stat card,
  chart card, card link, CTA banner, feature grid, hero, data table, code,
  accordion, disclosure, calculation, tab switcher, progress, funnel, bucket,
  pipeline and swipe deck. So do the navigation components: navbar, nav item,
  nav dropdown, bottom nav, mobile header, breadcrumbs and settings link. A host imports its
  look after `keystone_source.css`, and a gem ships one through
  `tailwind_imports`, both set up through the install local.
- **Registered looks.** Looks can also be registered by name, and each page
  gets one: the name another gem supplies for the request, then the configured
  default, each used only when registered. The layout's `<html>` tag carries
  `data-look="<name>"`, and a registered look file scopes its variables to
  `:root[data-look="<name>"]`. A host with no registered looks gets no
  `data-look`. Registering and choosing looks is set up through the install
  local.
- **Light, dark, system and custom themes.** Every component has dark-mode
  styling. The theme is chosen in this order: the user's choice stored in a
  cookie, then a mode another gem supplies, then light. System leaves the page
  to follow the operating system. Custom marks the page for a palette another
  gem defines. The theme toggle does not offer it, so a page reaches it when
  another gem supplies it. On a Turbo visit, the page being shown sets the
  theme, so a change to the mode on the server shows up without a full reload.
  Marking the layout with the theme is set up through the install local, and
  placing the toggle on a screen goes through the develop local.
- **Tailwind classes are static strings.** Class names are never interpolated,
  so Tailwind's scanner can find them. Widths and heights that depend on data,
  such as a progress bar or a bucket's fill, are set with an inline style
  instead. The host needs tailwindcss-rails v4+, and the engine tells Tailwind
  at boot where the component files are.
- **Interactivity is Stimulus.** Dropdowns, modals, dismissible alerts, file
  uploads, the color picker, the multi-select, tab switchers, accordions, the
  swipe deck, column pickers, info panels, line charts, clipboard copy
  and the theme toggle ship with the gem as Stimulus controllers registered once
  at install. A host writes no JavaScript to use them. Components that post
  somewhere, such as the column picker and the pipeline, post to endpoints the
  host app or another gem owns.
- Ruby >= 3.2. ViewComponent >= 2.0 and < 5.
