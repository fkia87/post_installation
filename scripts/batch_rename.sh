#!/bin/bash

remove() {
    while IFS=$'\n' read -r filename; do
        mv "$filename" "${filename//$to_remove/}"
    done < <(find "${dir-.}" -type f)
}

add_end() {
    while IFS=$'\n' read -r filename; do
        mv "$filename" "${filename}${to_add_end}"
    done < <(find "${dir-.}" -type f)
}

add_beginning() {
    while IFS=$'\n' read -r filename; do
        mv "$filename" "${to_add_beginning}${filename}"
    done < <(find "${dir-.}" -type f)
}

help() {
    printf "%s\n" "

Usage $0 OPTIONS STRING

Options:
-r , --remove                Remove STRING from all files in the current directory.

-ae , --add-end              Add STRING to the end of all file names in the current directory.

-ab , --add-beginning        Add STRING to the beginning of all file names in the current directory.

-d , --directory             Do the renaming in a custom directory. Default is current directory.
"
}

while (( $# >= 1 )); do
    case $1 in
    -r | --remove)
        to_remove="$2"
        remove
        shift 2
        ;;
    -ae | --add-end)
        to_add_end="$2"
        add_end
        shift 2
        ;;
    -ab | --add-beginning)
        to_add_beginning="$2"
        add_end
        shift 2
        ;;
    -h | --help)
        help
        exit
        ;;
    -d | --directory)
        dir="$2"
        shift 2
        ;;
    esac
done