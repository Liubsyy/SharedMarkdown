#!/bin/bash

#repository
stat_repository=$1
token=""
OS=$(uname)

function fetch_stargazers {
    local page=1
    local per_page=100
    local data

    while true
    do
        data=$(curl -s -H "Accept: application/vnd.github.v3.star+json" \
        -H "Authorization: ${token:+token $token}" \
        "https://api.github.com/repos/$stat_repository/stargazers?per_page=$per_page&page=$page")

        if [ ${#data} -lt 10 ]; then
            break
        fi

        starred_at=$(echo "$data" | grep -o '"starred_at": "[^"]*"' | awk -F'"' '{print $4}')

        if [ ${#starred_at} -lt 10 ]; then
            break
        fi

        # UTC +8h
        for timestamp in $starred_at
        do
            if [ "$OS" = "Linux" ]; then
                #linux
                new_time=$(date -u -d "$timestamp 8 hours" +"%Y-%m-%d")
            elif [ "$OS" = "Darwin" ]; then
                #mac
                new_time=$(date -v +8H -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%Y-%m-%d")
            fi

            echo "$new_time"
        done
        ((page++))
    done
}


if [ -z "$1" ]; then
    echo "Error: No parameter provided."
    echo "Usage: github_stars_stat.sh username/repository"
    exit 1
fi

try_data=$(curl -s -H "Accept: application/vnd.github.v3.star+json" \
-H "Authorization: ${token:+token $token}" \
"https://api.github.com/repos/$stat_repository/stargazers?per_page=1&page=1")
if echo "$try_data" | grep -q "API rate limit"; then
    echo "$try_data"
    exit 1
fi

if echo "$try_data" | grep -q "Not Found"; then
    echo "$try_data"
    exit 1
fi

echo "date          stars    sum(stars)"
fetch_stargazers | sort | uniq -c | awk 'BEGIN{sum=0} {sum+=$1; print $2 "\t" $1 "\t" sum}'

