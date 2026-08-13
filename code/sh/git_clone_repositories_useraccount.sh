#!/bin/bash

# Define an array containing the Git repository URLs
repos=(
    "tmp-niko"
    "tmp-envi"
    "del-envs"
    "niko"
    "tree"
    "tmp-envs"
    "invs"
    "ni"
    "nilo"
    "pathogens"
    "killio"
    "bits"
    "blueshell"
    "archive"
    "watney"
)

# Loop over each string element in the array
for repo in "${repos[@]}"; do
    echo "Cloning: $repo"
    git clone "git@github.com:vecritos/$repo.git"
done

