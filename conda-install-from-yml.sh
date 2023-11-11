#!/usr/bin/env bash

echo "This is deprecated, in case of containers install into base" > /dev/stderr
exit 1

usage="Usage: $(basename "$0") [-h] [-y] [FILE]
Install packages directly in environment from environment FILE in YAML format

    -h  show this help text and exit

Examples:
    conda-install-from-yml.sh environment.yml
"

# Handle input flags
while getopts ":h" option; do
    case $option in
        h)
            echo "$usage"
            exit;;
        \?)
            echo Error: Incorrect flag
            echo "$usage"
            exit;;
    esac
done

filepath=$1

if [[ -z $filepath ]]; then
    echo Error: No FILE given
    echo "$usage"
    exit
fi


# Translate channels and dependencies
channels=$(grep -v "^prefix:" $filepath | sed -ne '/channels:/,/dependencies:/ p' | sed -e '1d;$d' | sed -e 's/\s*-\s*/ -c /' | tr -d '\n')
dependencies=$(grep -v "^prefix:" $filepath | sed -ne '/dependencies/,/pip:/ p' | sed -e '1d;$d' | sed -e 's/\s\+-\s\+/ /' | tr -d '\n')
pip_dependencies=$(grep -v "^prefix:" $filepath | sed -e '1,/^\s*-\s*pip:\s*/d' | tr '\n' ' ' | sed 's/\s\+-\s\+/ /g')

#echo $channels
#echo $dependencies
#echo $pip_dependencies

# Install packages
conda install $channels $dependencies
pip install $pip_dependencies

