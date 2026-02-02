library(tidyverse)
library(rStrava)
library(httr)
library(reactable)

# Generate token for Strava ----------------------------------------------

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

# Activity List data -----------------------------------------------------

activity_list_df <- read_csv("swim_data.csv") |>
  filter(type == "Swim") |>
  select(id, name, start_date_local, distance, moving_time) |>
  mutate(distance = distance * 1000, id = as.character(id))

get_swim_laps <- function(activity_id, stoken) {
  laps_df <- get_laps(stoken, activity_id) |>
    select(lap_index, distance, moving_time, average_speed) |>
    mutate(across(everything(), as.numeric))

  laps_df
}

swim_with_laps_df <- activity_list_df |>
  mutate(laps = map(id, \(x) get_swim_laps(x, stoken)))

swims_jan <-
  swim_with_laps_df |>
  unnest(laps, names_sep = "_") |>
  select(
    id,
    name,
    start_date_local,
    laps_lap_index,
    laps_distance,
    laps_moving_time
  ) |>
  mutate(
    start_date_local = ymd_hms(start_date_local),
    year = year(start_date_local),
    month = month(start_date_local)
  ) |>
  filter(year == 2026, month == 1, )

swims_jan |>
  mutate(
    date_day = day(start_date_local),
    date_week_name = wday(start_date_local, label = TRUE),
    date_month_name = month(start_date_local, label = TRUE),
    date_label = glue::glue("{date_day}-{date_month_name} ({date_week_name})")
  ) |>
  select(date_label, laps_distance) |>
  reactable(
    groupBy = c("date_label"),
    columns = list(
      date_label = colDef(minWidth = 150),
      laps_distance = colDef(aggregate = "sum")
    ),
  )
