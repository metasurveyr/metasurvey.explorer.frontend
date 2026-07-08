# Ver RFC-MODULARIZACION.md · paquete metasurvey.explorer.frontend
# Adaptadores de autenticacion: envuelven el cliente
# metasurvey.explorer.backend::api_login()/api_register() y reconstruyen la forma
# list(ok, user, token, review_status, pending) que esperan los modulos de la app.
# (Antes esta logica vivia en el cliente HTTP propio de la Shiny, api_utils.R.)

# Build a RecipeUser object from the raw API user document.
.build_recipe_user <- function(doc) {
  if (is.null(doc)) {
    return(NULL)
  }
  inst <- NULL
  is_member <- !is.null(doc$user_type) &&
    doc$user_type == "institutional_member" &&
    !is.null(doc$institution)
  if (is_member) {
    inst <- metasurvey.core::RecipeUser$new(
      name = doc$institution,
      user_type = "institution"
    )
  }
  metasurvey.core::RecipeUser$new(
    name = doc$name,
    user_type = doc$user_type,
    email = doc$email,
    institution = inst
  )
}

# Log in through the API client. Returns the shape expected by mod_auth.R:
# list(ok, user, token, review_status, error). The client stores the token
# internally; we surface it too for the app's logged-in state.
login_user <- function(email, password) {
  result <- tryCatch(
    metasurvey.explorer.backend::api_login(email, password),
    error = function(e) list(ok = FALSE, error = conditionMessage(e))
  )

  if (isTRUE(result$ok) && !is.null(result$user)) {
    return(list(
      ok = TRUE,
      user = .build_recipe_user(result$user),
      token = result$token %||% getOption("metasurvey.api_token")
    ))
  }

  if (!is.null(result$review_status)) {
    return(list(
      ok = FALSE,
      error = result$error,
      review_status = result$review_status
    ))
  }

  list(
    ok = FALSE,
    error = result$error %||% "Invalid email or password"
  )
}

# Register through the API client. Returns list(ok, user, token, pending, error).
register_user <- function(name, email, password,
                          user_type = "individual",
                          institution = NULL) {
  result <- tryCatch(
    metasurvey.explorer.backend::api_register(
      name = name, email = email, password = password,
      user_type = user_type, institution = institution
    ),
    error = function(e) list(ok = FALSE, error = conditionMessage(e))
  )

  if (isTRUE(result$ok)) {
    return(list(
      ok = TRUE,
      pending = isTRUE(result$pending),
      user = .build_recipe_user(result$user),
      token = result$token %||% getOption("metasurvey.api_token")
    ))
  }

  list(
    ok = FALSE,
    error = result$error %||% "Registration failed"
  )
}

# Local null-coalescing helper (the app no longer sources api_utils.R which
# defined `%||%`).
`%||%` <- function(x, y) if (is.null(x)) y else x
