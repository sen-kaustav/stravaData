library(httr)
library(rStrava)
library(duckdb)

# Setup Strava authentication --------------------------------------------

res <- POST(
  "https://www.strava.com/oauth/token",
  body = list(
    client_id = Sys.getenv("STRAVA_CLIENT_ID"),
    client_secret = Sys.getenv("STRAVA_CLIENT_SECRET"),
    refresh_token = Sys.getenv("STRAVA_REFRESH_TOKEN"),
    grant_type = "refresh_token"
  ),
  encode = "form"
)

new_token <- content(res)$access_token

stoken <- config(
  token = oauth2.0_token(
    endpoint = NULL,
    app = oauth_app(
      "swim-stats",
      Sys.getenv("STRAVA_CLIENT_ID"),
      Sys.getenv("STRAVA_CLIENT_SECRET")
    ),
    credentials = list(access_token = new_token),
    cache = FALSE
  )
)

# Get current day's swim data --------------------------------------------

current_day_swim <- get_activity_list(stoken, after = Sys.Date() - 1) |>
  compile_activities()

# Add to database --------------------------------------------------------

con <- dbConnect(duckdb(), dbdir = "swim_data.duckdb")

if (length(current_day_swim)) {
  new_data <- compile_activities(current_day_swim) |> tibble()
  dbAppendTable(con, "swim_data", new_data)
}

# Disconnect -------------------------------------------------------------

dbDisconnect(con)
