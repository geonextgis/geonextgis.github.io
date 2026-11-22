Repo for my personal website: [https://geonextgis.github.io/](https://geonextgis.github.io/) created with [Quarto](https://quarto.org/).

The design and site structure are adapted from [Ben Black's website](https://github.com/blenback/blenback.github.io). The CV linked from the site lives in its own repository ([geonextgis/curriculum-vitae](https://github.com/geonextgis/curriculum-vitae)).

## Structure

| Path | What it does |
|------|--------------|
| `_quarto.yml` | Site config: navbar, theme, includes, pre-render scripts. |
| `_brand.yml`, `theme.scss` | Colours, fonts and all component styles. |
| `header.html`, `nav-scroll.html`, `bb-footer.html` | Web fonts, navbar scroll behaviour, custom footer. |
| `index.qmd` | Home page: hero, then publications / presentations / posts / beyond-the-papers listings. |
| `about.qmd` + `about/*.yaml` | About page: experience, education, skills, honours, workshops. |
| `publications.qmd` + `publications/*.yaml` | Journal articles and "Beyond the papers" (software and projects). |
| `presentations.qmd` + `presentations/presentations.yaml` | Presentations (one page each, generated from the YAML). |
| `posts.qmd` + `posts/*.qmd` | Blog posts. |
| `ejs/` | Listing templates (publication rows, timeline rows, skills chips). |
| `assets/` | Images (portrait, covers, paper grain). |
| `fetch-assets.R`, `create_presentation_qmds.R` | Pre-render steps (see below). |

## Content management

All content is plain YAML or Markdown. Edit a file, push to `main`, and the site rebuilds.

### Hero, footer, navbar
- Hero text and social icons: the HTML block at the top of `index.qmd`.
- Footer text and links: `bb-footer.html`.
- Navbar links and the "Download CV" button: `_quarto.yml`.
- Portrait: replace `assets/landing_portrait_cropped.jpg` with a square image.

### Publications
Add an entry to the top of `publications/publications.yaml` with `title`, `authors`, `year`, `journal`, `doi` and, optionally, `preprint_url`, `data_url`, `code_url`, `bibtex` and a `summary` (`overview` / `findings` / `methods` / `implications`, written as HTML), which adds a "Plain-language summary" toggle. The home page shows the 3 newest. Your name is highlighted wherever it appears as `Halder, K.` (see `highlight` in `ejs/publication_yearly.ejs`).

### Beyond the papers
`publications/other_outputs.yaml` holds one card per software package, project, tool or report (`title`, `path`, `image`, `description`, `categories`). The first four appear on the home page.

### Presentations
Presentations are managed through a YAML-based system:
- Presentation metadata is stored in `presentations/presentations.yaml`.
- `create_presentation_qmds.R` generates one `.qmd` per entry in `presentations/` (pre-render step).
- See `presentations/README.md` for every field, including PDF and slide embeds.

### Posts
Create `posts/YYYY-MM-DD-short-title.qmd` with `title`, `description`, `date`, `image` and `categories` in the front matter. Code in posts is frozen (`posts/_metadata.yml`), so run `quarto render` locally after editing a post that executes code, and commit `_freeze/`.

### About page
Edit `about/experience.yaml`, `about/education.yaml`, `about/skills.yaml`, `about/honours.yaml` and `about/workshops.yaml`. The order in each file is the order on the page.

### Optional: a separate data repository
Both pre-render scripts run automatically (see `_quarto.yml`). By default `fetch-assets.R` does nothing and the local YAML files are used. To share one source of truth with other projects, set the environment variable `SITE_DATA_REPO=owner/repo` (for example in the workflow). The script then downloads `publications.yaml`, `other_outputs.yaml`, `presentations.yaml` and an `assets/` folder from that repository's root before rendering.

## Rendering locally

Requirements: [Quarto](https://quarto.org/docs/get-started/) (≥ 1.4) and R with the `yaml`, `httr`, `jsonlite` and `rmarkdown` packages.

```sh
quarto preview   # live preview
quarto render    # full build into docs/
```

## Deployment (GitHub Pages)

1. Create a repository named **`geonextgis.github.io`** and push this folder to its `main` branch.
2. Create the publishing branch once:
   `git checkout --orphan gh-pages && git reset --hard && git commit --allow-empty -m "init gh-pages" && git push origin gh-pages && git checkout main`
3. In **Settings → Pages**, set *Source* to *Deploy from a branch*, branch `gh-pages`, folder `/ (root)`.
4. On every push to `main`, `.github/workflows/quarto_render.yml` renders the site and publishes it to `gh-pages`.
