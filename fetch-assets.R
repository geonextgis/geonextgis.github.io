#!/usr/bin/env Rscript

cat("Fetching assets from GitHub...\n")

# Load required packages
if (!require("httr", quietly = TRUE)) {
  install.packages("httr", repos = "https://cloud.r-project.org")
  library(httr)
}
if (!require("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite", repos = "https://cloud.r-project.org")
  library(jsonlite)
}

# Ensure publications directory exists
if (!dir.exists("publications")) {
  dir.create("publications")
}

# Ensure assets directory exists at the base of the repo
if (!dir.exists("assets")) {
  dir.create("assets")
}

# ------------------------------------------------------------------
# Data source
# ------------------------------------------------------------------
# By default the site uses the YAML files committed in this repository
# (publications/, presentations/) and nothing is downloaded.
#
# To keep the content in a separate data repository instead (one source of
# truth shared with your CV), set the SITE_DATA_REPO environment variable to
# "owner/repo" (or replace the empty default on the next line). It must
# contain publications.yaml, other_outputs.yaml, presentations.yaml (and,
# optionally, an assets/ folder) at its root; they then overwrite the local
# copies at render time.
data_repo <- Sys.getenv("SITE_DATA_REPO", unset = "")
repo_owner <- if (nzchar(data_repo)) strsplit(data_repo, "/")[[1]][1] else ""
repo_name <- if (nzchar(data_repo)) strsplit(data_repo, "/")[[1]][2] else ""
branch <- Sys.getenv("SITE_DATA_BRANCH", unset = "main")

if (!nzchar(repo_owner) || !nzchar(repo_name)) {
  cat("No data repository configured - using the local YAML files.\n")
  quit(save = "no", status = 0)
}

raw_base <- sprintf(
  "https://raw.githubusercontent.com/%s/%s/%s",
  repo_owner,
  repo_name,
  branch
)

# Add timestamp to bypass GitHub's CDN cache
cache_buster <- format(Sys.time(), "%Y%m%d%H%M%S")

# Define YAML files to download (local path = remote file name)
files <- list(
  "publications/publications.yaml" = "publications.yaml",
  "publications/other_outputs.yaml" = "other_outputs.yaml",
  "presentations/presentations.yaml" = "presentations.yaml"
)
files <- lapply(files, function(f) {
  sprintf("%s/%s?cache=%s", raw_base, f, cache_buster)
})

# Download each YAML file
for (filepath in names(files)) {
  url <- files[[filepath]]
  tryCatch(
    {
      # download to a temp file first so a failed request never wipes the local copy
      tmp <- tempfile(fileext = ".yaml")
      download.file(url, tmp, quiet = TRUE, mode = "wb")
      file.copy(tmp, filepath, overwrite = TRUE)
      cat("Downloaded", basename(filepath), "\n")
    },
    error = function(e) {
      cat(
        "Error downloading",
        basename(filepath),
        ":",
        conditionMessage(e),
        "\n"
      )
    }
  )
}

# Download all files from the assets folder using GitHub API
cat("\nDownloading assets folder...\n")
assets_api_url <- sprintf(
  "https://api.github.com/repos/%s/%s/contents/assets?ref=%s",
  repo_owner,
  repo_name,
  branch
)

tryCatch(
  {
    # Get list of files in the assets folder
    response <- GET(assets_api_url)

    if (status_code(response) == 200) {
      assets_list <- fromJSON(content(response, "text", encoding = "UTF-8"))

      # Download each file to the base assets directory
      for (i in seq_len(nrow(assets_list))) {
        if (assets_list$type[i] == "file") {
          file_name <- assets_list$name[i]
          download_url <- assets_list$download_url[i]
          local_path <- file.path("assets", file_name)

          tryCatch(
            {
              download.file(download_url, local_path, quiet = TRUE, mode = "wb")
              cat("Downloaded asset:", file_name, "\n")
            },
            error = function(e) {
              cat(
                "Error downloading",
                file_name,
                ":",
                conditionMessage(e),
                "\n"
              )
            }
          )
        }
      }
    } else {
      cat(
        "Warning: Could not access assets folder (HTTP",
        status_code(response),
        ")\n"
      )
      cat("Assets folder may not exist yet in the source repository.\n")
    }
  },
  error = function(e) {
    cat("Error accessing GitHub API:", conditionMessage(e), "\n")
    cat("Assets were not downloaded.\n")
  }
)

cat("\nAll YAML content files and assets updated successfully!\n")
