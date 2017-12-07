#!/bin/bash

########################################################################################
#
# Sets the directory of this script to the DIR variable.
#
########################################################################################
function source_dir {
    local source_dir="${BASH_SOURCE[0]}"
    DIR="$( dirname "${source_dir}" )"
    while [ -h "${source_dir}" ]
    do
        local source_dir="$(readlink "${source_dir}")"
        [[ "${source_dir}" != /* ]] && source_dir="${DIR}/${source_dir}"
        DIR="$( cd -P "$( dirname "${source_dir}"  )" && pwd )"
    done
    DIR="$( cd -P "$( dirname "${source_dir}" )" && pwd )"
}

source_dir

########################################################################################
#
# prints a given message to stderr if verbose
#
#
# 1st param: verbose flag. Muste be true of false
# 2st param: message to print to stderr
#
########################################################################################
function vperr () {
    if [ "${1}" == true ]; then
        local MSG="${2}"

        local oldifs="${IFS}"
        IFS=''
        (>&2 echo ${MSG})
        IFS="${oldifs}"
    fi
}

########################################################################################
#
# prints a given message to stderr.
#
#
# 1st param: message to print to stderr
#
########################################################################################
function perr () {
    vperr true "${1}"
}

########################################################################################
#
# Prints usage with command line parameter and terminates.
#
########################################################################################
function usage () {
    perr "JPEG to SVG primitives with blur effect"
    perr " "
    perr "Parameters:"
    perr " "
    perr "  -i  -  required  :  Image file"
    perr "  -d  -  optional  :  Gausian blur devitaion.Default: 12"
    perr "  -n  -  optional  :  Number of primitives"
    
    exit 1
}

deviation=12
primitives=30

while getopts i:d:n: opt
do
    case "${opt}" in
        i) eval "image_file='${OPTARG%/}'";;
        d) eval "deviation='${OPTARG}'";;
        n) eval "primitives='${OPTARG%/}'";;
        h) usage ;;
        \?) usage
    esac
done

filename_with=$(basename "$image_file")
extension="${filename##*.}"
filename="${filename_with%.*}"
dirname=$(dirname "${image_file}")

frame_width=$(convert "${image_file}" -format "%w" info:)
frame_size=$(wc -c < "${image_file}" | tr -d '[:space:]')

echo "filename,filesize,width,svg_blur_size,svg_blur_brotli_size,svg_blur_gzip_size" > "${dirname}/${filename}.csv"

OLDIFS="${IFS}"
IFS=","
while read mode mode_name; do
    primitive -v -m "${mode}" -n "${primitives}" -s "${frame_width}" -i "${image_file}" -o "${dirname}/${filename}.${mode_name}.svg"
    blur4primitive -d "${deviation}" "${dirname}/${filename}.${mode_name}.svg" > "${dirname}/${filename}.${mode_name}.blur.svg"
    bro -i "${dirname}/${filename}.${mode_name}.blur.svg" -o "${dirname}/${filename}.${mode_name}.blur.svg.br"
    gzip -c "${dirname}/${filename}.${mode_name}.blur.svg" > "${dirname}/${filename}.${mode_name}.blur.svg.gz"
    
    svg_size=$(wc -c < "${dirname}/${filename}.${mode_name}.blur.svg"       | tr -d '[:space:]')
    brotli_size=$(wc -c < "${dirname}/${filename}.${mode_name}.blur.svg.br" | tr -d '[:space:]')
    gzip_size=$(wc -c < "${dirname}/${filename}.${mode_name}.blur.svg.gz"   | tr -d '[:space:]')
    
    echo "${filename_with},${frame_size},${frame_width},${svg_size},${brotli_size},${gzip_size}" >> "${dirname}/${filename}.csv"
    
done < "${DIR}/2primitive.config"

IFS="${OLDIFS}"
