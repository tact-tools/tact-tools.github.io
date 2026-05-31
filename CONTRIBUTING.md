# Contributing to Tact Website

Thank you for your interest in contributing!

## Development Setup

This repository is the static website for `tact.tools`. The first version is
dependency-free HTML and CSS, so there is no package install or build step for
ordinary changes.

### Prerequisites

- A modern browser.
- Python 3, if you want to serve the directory locally instead of opening
  `index.html` directly.

### Local Preview

Open `index.html` directly in a browser, or serve the directory with any static
file server:

```bash
python3 -m http.server 8080
```

Before sending HTML, CSS, or asset changes, preview the page at desktop and
mobile widths. Check that text does not overlap, images load, and the page still
works without a JavaScript build pipeline.

Docs-only changes do not need a browser smoke check unless they change setup or
verification instructions.

### Assets

The screenshots in `assets/screenshots/` come from synthetic Android emulator
captures in `../tact-keyboard-android/artifacts/`. Do not capture or commit real
private input, clipboard contents, passwords, messages, or account data.

Commit only the assets the site needs. Local preview captures, generated full
PNG crops, logs, caches, dependency directories, and build outputs should stay
out of the repository.

## Commit Message Guidelines

We follow strict commit message conventions to maintain a clear and
understandable project history.

### Key Principles

- **Write for drive-by reviewers with limited context.** Assume the reader does
  not know the project well.
- **You are the maintainer; write to a casual reader.** The commit message is
  you explaining the change to someone unfamiliar with the codebase. Never refer
  to maintainers in the third person.
- **Tell a story.** The events in history are connected, and that connection
  should be considered when crafting messages. Do not treat each commit as an
  isolated writing exercise. If a series of commits contribute collectively to a
  goal, each commit message should describe how it helps achieve that goal.
  Early commits can foreshadow later commits if it helps tell the story.
- **Separate independent series.** A dirty worktree can contain multiple
  unrelated commit series. Split them into separate series with separate opening
  and concluding commits instead of forcing one message thread across all
  unstaged changes.
- **Introduce the series in its first commit.** When a commit opens a
  multi-commit series, its message should name the larger goal and explain why
  the series exists, even if the first change is narrow groundwork. Do not limit
  the opening message to mechanics that only matter to that first change.
- **Conclude the series in its final commit.** The final commit should make
  clear that the series has reached its intended goal. Its message should close
  the thread opened by the first commit instead of only describing the last small
  change.
- **Use the tense that reflects the state of the project just before the commit
  is applied.** When discussing the old behavior, treat it as the selected
  behavior. When discussing the changes, treat them as new behavior.
- **Describe problems at the product level, not just the file level.** Focus on
  what users experience or what you find problematic as the maintainer, not only
  what is missing in a specific file or function.
- **Focus on missing capabilities, not symptoms.** Documentation gaps, code
  organization, and naming issues are often symptoms. Identify the underlying
  limitation or missing behavior that motivates the change.
- **Do not describe secondary effects as the primary problem.** Code
  organization, maintainability, or cleanliness are rarely the main reason for a
  change.
- **Be precise about scope.** If a change only improves one aspect of a problem,
  do not imply it fully solves it.
- **If the commit is a step toward a larger feature, say so explicitly.**
  Describe the end goal briefly, then explain how this commit moves toward it.
- **Name the feature goal in early groundwork commits.** If a commit mainly
  exists to enable a later user-facing feature, say what that feature is and why
  it matters instead of presenting the commit as isolated infrastructure work.
- **Prefer concrete limitations over vague judgments.** Avoid words like
  "cumbersome", "better", or "improved" without explaining why.
- **Do not use `Co-Authored-By` for contributions produced from AI.** Only use
  it for human co-authors.
- **Only use the word `this` when referring to the commit itself.** Use `that`
  or similar for other contexts.
- **Wrap body paragraphs at 75 characters.**
- **Be humble and forward thinking.** Avoid words like "comprehensive" or
  "crucial", and avoid a tone that could sound like bragging or seem
  short-sighted.
- **Do not invent concise self-describing labels for internal ideas and use them
  casually,** expecting the reader to implicitly know what they should mean.
  Explain things in a way that reduces cognitive load on the reader.

### Format

Commit messages should follow this structure:

#### First Line (Summary)

```text
prefix: Concise summary of the change
```

- Use a short, lowercase prefix such as `site:`, `assets:`, `docs:`, `style:`,
  or `deploy:`.
- Capitalize the first word of the summary after the colon.
- Keep the entire line under 72 characters.
- If unsure which prefix to use, run `git log --pretty=oneline FILE` and see
  what prefixes were used previously.

#### First Paragraph

Describe the program's selected state at this point in history.

Summarize what capabilities, interfaces, or documentation exist in the project
immediately before this commit is applied. This is the program's state, not the
user's situation. Focus on what the program has or provides, not on what users
must do or cannot do.

If this commit is part of a series, the first paragraph must reflect the
cumulative state after all previous commits in the series. For example, if
earlier commits added screenshots and deployment metadata, this paragraph should
state "The site has product screenshots and deployment metadata" rather than
"The site only has static markup."

If this is the opening commit in a feature series, the later paragraphs should
name the feature goal directly. Do not describe the commit as generic cleanup or
infrastructure when it is really the first step toward a specific user-facing
capability.

Do not describe the diff, the change itself, or future goals.

#### Second Paragraph

Explain the underlying problem from the appropriate perspective.

Choose the perspective based on who experiences the problem:

- Use first-person maintainer perspective for internal concerns such as missing
  verification steps, asset provenance, deployment metadata, or repository
  structure. You are the maintainer; frame as "The project lacks X" or "The site
  does not provide Y", never as "Maintainers cannot X."
- Use user perspective for external concerns such as confusing copy, missing
  product information, broken responsive layouts, or unclear navigation. Frame
  as "Users cannot X" or "Users must Y."

Describe what is non-obvious, hard to discover, confusing, missing, or limited
about the selected state. Focus on the broader problem and future goals, not
just the specific file being edited.

Prefer the broadest accurate framing of the problem.

Useful tests:

- Would this problem still exist even if the specific file being edited were
  perfect?
- Is this something users would notice, or only you as the maintainer?

For opening commits in a feature series, prefer framing the problem around the
missing user-facing capability instead of the missing internal helper. For
example, "Users cannot see how Tact behaves in terminal workflows" is usually
stronger than "The project does not provide terminal screenshot assets."

#### Third Paragraph

Describe how the commit addresses one part of that problem.

Be precise about scope. If the commit only addresses one path, viewport, asset,
or document, say so clearly rather than implying the entire problem is solved.

If the commit introduces infrastructure or an early step toward a larger
feature, describe it as such.

For the first commit in a series, describe how the commit begins moving the
project toward the larger goal. For the final commit, describe how it completes
or reaches the goal when that is true.

Start this paragraph with `This commit`.

Use natural prose such as:

- `This commit addresses that by ...`
- `This commit begins adding support for ... by ...`
- `This commit lays groundwork for ... by ...`

#### Fourth Paragraph

Use it for every commit in a multi-commit series. For non-final commits, use
future tense because the work has not happened yet, and be specific about the
next step rather than vague.

For example:

- `Subsequent commits will provide ...`
- `In the future, <behavior> will change to ...`

The final commit should conclude the series goal introduced by the opening
commit in a fourth paragraph instead of pointing toward more work. For the
penultimate commit, refer to the upcoming final commit in the singular, such as
`The final commit will ...`, instead of saying `subsequent commits`. Vary the
phrasing across a series.

### Checklist

Before finalizing a commit message, check:

- Does the summary use a fitting prefix and stay under 68 characters?
- Does the first paragraph describe the program's selected state, not the patch?
- Does the first paragraph describe the program's state, not the user's
  situation?
- If this is part of a series, does the first paragraph accurately reflect the
  cumulative state after all previous commits?
- If the worktree contains multiple independent series, are they split into
  separate series?
- If this is the first commit in a series, does the message introduce the whole
  series goal rather than only the first change?
- If this is the final commit in a series, does the message conclude the series
  goal rather than read like another incremental step?
- Does the second paragraph use the appropriate perspective?
- Does the second paragraph describe the real problem from either the user's or
  your own maintainer perspective?
- Is the problem broader than just the file being edited?
- Does the message focus on a missing capability rather than a symptom?
- If this is the first commit in a feature series, does the message name the
  eventual user-facing feature rather than only the internal machinery?
- Does the third paragraph open with `This commit` and clearly state what this
  commit does without overstating its impact?
- If this is part of a series, does it show progression with words such as
  "begins", "continues", or "completes"?
- If this is an incremental step, does it clearly say so?
- If this is the penultimate commit in a series, does the fourth paragraph name
  what the upcoming final commit will do?
- If this is an earlier non-final commit in a series, does the fourth paragraph
  name what subsequent commits will do?
- Do body paragraphs wrap at 75 characters?

### Example: Single Commit

```text
site: Add terminal workflow screenshot

The website describes Tact's terminal protections but only shows the keyboard
in prose-writing contexts.

Users evaluating the project cannot see how paste protection appears in a
terminal workflow, so one of the product's core safety behaviors remains
abstract.

This commit addresses that gap by adding a synthetic terminal screenshot and
using it in the workflow section. The change only covers the paste-protection
state; other terminal states can be shown separately if they need their own
explanation.
```

### Example: Commit Series

Notice how the first paragraph evolves to reflect the cumulative state, and how
each commit shows progression toward the stated goal:

**Commit 1:**

```text
assets: Add prose screenshot source

The website has a static product overview but does not yet include screenshot
assets that show the Android keyboard in use.

Users evaluating Tact cannot inspect the keyboard layout or suggestion strip
from the website, which makes the product behavior harder to understand before
installation.

This commit begins adding product screenshots by checking in the synthetic prose
capture source and recording where it came from.

Subsequent commits will prepare web-ready versions and place them on the page.
```

**Commit 2:**

```text
assets: Add web-ready prose screenshot

The website has a synthetic prose screenshot source but no optimized image that
the static page can serve efficiently.

Users should be able to see the keyboard without downloading oversized capture
artifacts that only exist to preserve source evidence.

This commit continues the screenshot work by adding a compressed WebP version
of the prose capture for use on the public page.

The final commit will connect the prepared screenshot to the site layout.
```

**Final commit:**

```text
site: Show prose screenshot in the overview

The website has a synthetic prose screenshot and an optimized WebP asset, but
the public page still presents the overview without a product image.

Users evaluating Tact cannot inspect the keyboard layout from the main website
flow even though the needed image asset is available.

This commit completes the initial screenshot path by placing the prose image in
the overview and giving it responsive sizing.

The website now shows the Android keyboard in context while keeping the source
capture and served asset separate.
```

### Anti-Patterns to Avoid

Avoid writing in past tense about the old state:

```text
The site used to only show text...
```

Prefer present tense about the selected state:

```text
The site currently describes Tact without product screenshots.
```

Avoid describing the change in the first paragraph:

```text
This commit adds responsive image sizing to the homepage...
```

Prefer describing what exists today:

```text
The homepage has product screenshots with fixed desktop-oriented sizing.
```

Avoid confusing a symptom with the real problem:

```text
Users reading the homepage cannot find the CNAME value.
```

Prefer describing the broader problem first:

```text
The repository does not document how the static site is published.
```

Then describe the narrower gap if relevant:

```text
The README does not currently explain the custom domain record.
```

Avoid framing internal structure as the problem:

```text
Without an organized assets directory, the code may become harder to maintain.
```

Prefer describing the missing capability:

```text
The site does not yet provide workflow-specific screenshots.
```

Avoid vague value judgments:

```text
The homepage is cumbersome to scan.
```

Prefer concrete limitations:

```text
The homepage places terminal and prose workflows in one continuous block, so
users cannot compare those contexts quickly.
```

Avoid overstating the impact of the commit:

```text
This commit solves screenshot discoverability.
```

Prefer precise scope:

```text
This commit addresses that by adding the prose screenshot to the overview.
```

Avoid describing the program's state inaccurately in a series:

```text
site: Add terminal screenshot

The website only has text descriptions of Tact.
```

Prefer reflecting the cumulative state after previous commits:

```text
site: Add terminal screenshot

The website shows Tact in prose-writing contexts but does not show terminal
workflows.
```

Avoid describing user situations in the first paragraph:

```text
Users must imagine how the keyboard looks.
```

Prefer describing the program's state:

```text
The website describes Tact's keyboard behavior without screenshots.
```

## Making Changes

1. **Keep commits atomic.** Each commit should represent one logical change.
2. **Stage deliberately.** Use `git-stage-batch`, `git add -p`, IDE staging, or
   an equivalent workflow to split larger working directory changes into
   reviewable commits.
3. **Follow existing style.** Keep the site dependency-free unless the project
   deliberately adds a build pipeline. Match the existing HTML and CSS patterns
   before introducing new structure.
4. **Respect asset provenance.** Use synthetic captures and document where
   externally derived or generated assets came from.

### Commit Series Ordering

Order multi-commit series as repeated implementation steps and their related
follow-up commits:

```text
implementation -> assets -> docs
implementation -> assets -> docs
...
```

Do not put several implementation commits first and then collect the asset or
documentation commits at the end. Each asset or documentation commit should sit
immediately after the smallest implementation commit it supports or explains.

If one implementation change needs more than one follow-up commit because of
repository rules, keep those follow-ups together before moving to the next
implementation. Use the order `assets`, then `docs` unless a specific dependency
requires otherwise.

When shared groundwork is needed, commit the groundwork first. Then repeat the
same grouped pattern for each page section, workflow, or implementation that
adopts that groundwork.

## Questions?

Feel free to open an issue for discussion before starting major work.
