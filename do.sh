DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tempDir=`mktemp -d`

$DIR/download_rspec_files.sh $tempDir
ruby $DIR/combine_files.rb $tempDir './.rspec_failed_examples'
