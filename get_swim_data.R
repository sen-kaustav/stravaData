library(httr)
library(rStrava)
library(dplyr)
library(readr)

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


# Manually overwrite data ------------------------------------------------

# all_activities <- get_activity_list(stoken)
# all_activities |>
#   compile_activities() |>
#   tibble() |>
#   write_csv("swim_data.csv")

# Get current day's swim data --------------------------------------------

current_day_swim <- get_activity_list(stoken, after = Sys.Date() - 1)

# Add to file ------------------------------------------------------------

if (length(current_day_swim)) {
  data <- read_csv("swim_data.csv")
  new_data <- compile_activities(current_day_swim) |>
    tibble() |>
    type_convert(col_types = spec(data))

  if (!all(new_data$id %in% data$id)) {
    # Add to data only if activity doesn't already exist
    bind_rows(data, new_data) |>
      write_csv("swim_data.csv")
  }
}
