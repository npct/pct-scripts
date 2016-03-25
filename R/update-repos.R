# Aim: pull latest versions of the repositories needed to build the PCT

# Testing git2r for using the repo
library(git2r)
repo = repository(".")
workdir(repo)
commits(repo)[[1]]

add()
