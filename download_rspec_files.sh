upstreamBranch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD@{upstream})
regex="^([^/\]+)\/(.+)"
if [[ $upstreamBranch =~ $regex ]]
then
    upstream="${BASH_REMATCH[1]}"
    branch="${BASH_REMATCH[2]}"
else
    exit 1
fi

remote=`git remote get-url ${upstream}`
regex="github.com[:\/](.+)\/(.+)\.git"
if [[ $remote =~ $regex ]]
then
    username="${BASH_REMATCH[1]}"
    project="${BASH_REMATCH[2]}"
else
    exit 1
fi


latestArtifacts=`curl -s -u $(cat ~/.circleci.token): "https://circleci.com/api/v1.1/project/github/${username}/${project}/latest/artifacts?branch=${branch}"`

rspecPersistanceArtificats=`echo $latestArtifacts | jq '.[] | {path: .path, url: .url} | select(.path|endswith(".rspec_failed_examples"))'`

urls=`echo $rspecPersistanceArtificats | jq -r '.url'`
baseDir=$1

index=1
for url in $urls
do curl -s -u $(cat ~/.circleci.token): $url > $baseDir/$index.txt;
    index=$(expr $index + 1)
done;

echo $baseDir
