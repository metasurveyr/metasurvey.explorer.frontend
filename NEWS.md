# metasurvey.explorer.frontend 0.1.0

* Initial release. Shiny explorer UI for metasurvey recipes and workflows,
  extracted from the `metasurvey` monolith (now
  [`metasurvey-legacy`](https://github.com/metasurveyr/metasurvey-legacy)) as
  part of the modularization suggested by the rOpenSci review. See
  `MIGRATION.md`.
* Launch with `explore_recipes()`.
* The app's own duplicated HTTP client (`api_utils.R`) was removed; all API
  calls now go through the `metasurvey.explorer.backend` client (`api_*`
  functions). Recipe/RecipeWorkflow objects come from `metasurvey.core`.
