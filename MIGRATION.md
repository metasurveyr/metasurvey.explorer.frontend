# Migración: metasurvey.explorer.frontend

**UI Shiny** del explorador de recipes/workflows, extraída del monolito `metasurvey`
(renombrado a [`metasurvey-legacy`](https://github.com/metasurveyr/metasurvey-legacy))
como parte de la modularización sugerida por la revisión de rOpenSci. Ver
`RFC-MODULARIZACION.md` en el repo legacy.

> **Nombre:** repo y paquete `metasurvey.explorer.frontend` (con puntos; R no admite
> guiones). Repo renombrado de `metasurvey.explorer-frontend` (Opción 2 del RFC).

Responsabilidad: interfaz visual (`explore_recipes()`) para navegar, buscar y previsualizar
recipes y workflows. Habla con la API a través del cliente `metasurvey.explorer.backend`.

## Cambio principal: se eliminó el cliente HTTP duplicado

La Shiny tenía su **propio** cliente HTTP (`inst/shiny/R/api_utils.R`: `shiny_api_request`,
`shiny_fetch_recipes`, `shiny_login`, ...), un duplicado de `httr2` que hablaba directo con
la API. **Se eliminó por completo.** Ahora todos los módulos usan las funciones `api_*` de
`metasurvey.explorer.backend`:

| Antes (`shiny_*` en api_utils.R) | Ahora (cliente) |
|---|---|
| `shiny_fetch_recipes()` | `api_list_recipes(limit = 200)` |
| `shiny_fetch_workflows()` | `api_list_workflows(limit = 200)` |
| `shiny_fetch_anda_variables()` | `api_get_anda_variables()` |
| `shiny_star/get_stars/add_comment/...` | `api_star_recipe`/`api_get_recipe_stars`/`api_comment_recipe`/... (split recipe/workflow) |
| `shiny_increment_downloads` / `shiny_incr_wf_downloads` | `api_download_recipe` / `api_download_workflow` |
| `shiny_get_recipe_dependents` | `api_get_recipe_dependents` |
| `shiny_login` / `shiny_register` | `api_login` / `api_register` (envueltos por `login_user`/`register_user` en `auth_helpers.R`) |
| `shiny_fetch_pending_users` / `approve` / `reject` / `generate_token` | `api_pending_users` / `api_approve_user` / `api_reject_user` / `api_generate_token` (**nuevas** en el cliente) |
| `parse_recipe_doc` | eliminado — `api_list_recipes`/`api_get_recipe` ya devuelven objetos `Recipe` |

El cliente gestiona el **token internamente** (`options(metasurvey.api_token)`), así que se
quitó el argumento `token` de todas las llamadas autenticadas.

## Archivos

| Archivo aquí | Origen / nota |
|---|---|
| `R/run_app.R` | `metasurvey-legacy/R/run_app.R` (`explore_recipes()`; `system.file` apunta al nuevo paquete; guards de deps) |
| `inst/shiny/app.R` | idem; `library(metasurvey)` → `requireNamespace` de core+cliente + `configure_api()` al arranque |
| `inst/shiny/R/mod_auth.R` | reescrito: usa `login_user`/`register_user` |
| `inst/shiny/R/mod_explore.R` | reescrito: `api_*` de recipes |
| `inst/shiny/R/mod_explore_workflows.R` | reescrito: `api_*` de workflows |
| `inst/shiny/R/mod_profile.R` | reescrito: `api_*` admin + `api_list_recipes(user=...)` |
| `inst/shiny/R/ui_components.R` | UI pura (incluye `format_edition`), sin cambios de lógica |
| `inst/shiny/R/auth_helpers.R` | **nuevo** — `login_user`/`register_user` que adaptan la response del cliente a la forma que esperan los módulos (construyen `RecipeUser`); + `%||%` local |
| `inst/shiny/Dockerfile`, `inst/rstudio/addins.dcf` | idem |

Eliminados: `api_utils.R` completo (cliente HTTP propio), `parse_recipe_doc`,
`example_recipes`/`example_workflows` (dead code), y el modo offline (`.local_users`,
`hash_password`).

## Cambio acoplado en el cliente

`metasurvey.explorer.backend` ganó 4 funciones para los endpoints admin que la Shiny
necesitaba y no existían: `api_pending_users()`, `api_approve_user()`, `api_reject_user()`,
`api_generate_token()`. Así la Shiny no necesita `httr2`.

## Dependencias

- **Suggests**: `metasurvey.core`, `metasurvey.explorer.backend`, `shiny`, `bslib`,
  `bsicons`, `htmltools`. La app vive en `inst/shiny/`; `explore_recipes()` verifica su
  presencia con `requireNamespace()`.

R CMD check: 0 errors, 0 warnings, 0 notes. Tests: 6 pass (explore_recipes). La app se
sourcea y arma UI (`bslib_page`) + server correctamente en un smoke test.
