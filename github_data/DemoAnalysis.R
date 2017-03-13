
MailType <- function(email)
{
  x <- sapply(strsplit(email, "@", fixed = TRUE), function(x){x[2]})
  trimws(x, "b")
}


CorrectRepoLink <- function(gitData)
{
  repoSplitted <- strsplit(gitData[, ReadmeLink], "/", fixed = TRUE)
  gitData[, GitHubUser := trimws(GitHubUser, "b")]
  gitData[, GitUserName := sapply(repoSplitted, function(x){x[4]})]
  gitData[, AccountURL := sapply(repoSplitted, function(x){paste(x[1:4], collapse = "/")})]
  gitData[, RepoName := sapply(repoSplitted, function(x){x[5]})]
  gitData[, RepoNameCorrected := gsub(".git", "", gitData[, RepoName], fixed = TRUE)]
}


GetCommitData <- function(x)
{
  data.table(
    sha = slot(x, "sha"),
    author_name = slot(slot(x, "author"), "name"),
    author_email = slot(slot(x, "author"), "email"),
    author_when = slot(slot(slot(x, "author"), "when"), "time"),
    committer_name = slot(slot(x, "author"), "name"),
    committer_email = slot(slot(x, "author"), "email"),
    committer_when = slot(slot(slot(x, "author"), "when"), "time"),
    summary = slot(x, "summary"),
    message = slot(x, "message")
  )
}


# repo = gitData[4, CorrectedRepo]
# colnames(CloneAndExtract(gitData[4, CorrectedRepo], "tmp"))

CloneAndExtract <- function(repo, tmpDir)
{
  cat(repo)

  if (!file.exists(tmpDir))
  {
    dir.create(tmpDir)
  } else
  {
    unlink(tmpDir, force = TRUE, recursive = TRUE)
    dir.create(tmpDir)
  }

  file.remove(list.files(tmpDir))

  # clone repo
  res <- tryCatch(
  {
    git2r::clone(repo, tmpDir)
    TRUE
  }, error = function(e) {FALSE})

  if (!res) return(
      data.table(
      sha = as.character(NA), author_name = as.character(NA), author_email = as.character(NA),
      author_when = as.double(NA), committer_name = as.character(NA), committer_email = as.character(NA),
      committer_when = as.double(NA), summary = as.character(NA), message = as.character(NA)
    ))

  gitRepo <- repository(tmpDir)
  commitData <- git2r::commits(gitRepo)

  rbindlist(lapply(commitData, GetCommitData))  # extract commit data
}

