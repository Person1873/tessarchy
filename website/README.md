# Tessarchy project site

Dependency-free static site for https://thediamondsaint.github.io/tessarchy/.
Source lives here; artwork comes from `shell/artwork`, real VM captures from
`assets/screenshots`. Generated output belongs in ignored `dist/`.

Build into a **new** directory:

```bash
python3 scripts/build-site.py --output dist/website
python3 -m http.server 8765 --directory dist/website --bind 127.0.0.1
```

The builder refuses existing destinations. Pick a new output for another build.
No Node packages or host dependencies are installed.

The Pages workflow rebuilds and publishes on changes to source, shell, docs,
reference brief and screenshots on `build/live-iso` or `main`. The current
public development source is `build/live-iso`; keep these branches in sync when
merging the project. GitHub Pages is configured for Actions deployments and
allows these two branches. No source is merged automatically.

A build bundles current public release metadata; the browser additionally reads
public GitHub release and commit metadata, with usable fallback links on failure.
No token is sent to visitors. Screenshots and feature descriptions are reviewed
content: refresh them when behavior changes. Keep development features separate
from features in published ISO releases. UI changes do not rebuild an ISO.

The website's model tabs support arrow keys, Home/End, visible keyboard focus,
image enlargement, original downloads, and a screenshot ZIP. Reduced motion is
respected. There are no accounts, analytics, paid services, or remote fonts.
