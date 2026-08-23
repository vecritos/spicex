#!/bin/bash

# define git stuff to clone using ssh
username="my-git-username"
repos=(
    "tmp-uno"
    "tmp-dos"
)

for repo in "${repos[@]}"; do
    echo "Cloning: $repo"
    git clone "git@github.com:$username/$repo.git"
done

