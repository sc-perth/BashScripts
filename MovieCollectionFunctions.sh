#!/bin/bash
# Credit: perth@semicosmic.net
# License: Do whatever you want.

refreshMCF() {
  . ~/bashScripts/MovieCollectionFunctions.sh
}

fixYear() {
  find . -depth -regextype grep -regex '.*\[[0-9]\{4\}\].*' \
  | while IFS=' ' read -r f; do
    mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr '[' '('|tr ']' ')')"
  done
}

fixSpaces() {
  find . -depth -name '* *' \
  | while IFS=' ' read -r f; do
    mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)"
  done
}

fixMovieFileNames() {
  fixSpaces
  fixYear
}

compareListToFiles()
{
  compareListToFiles_usage() {
echo -e "compareListToFiles:
-h \t Print this help message
-d \t Directory to find files in
-i \t Input file containing a \\\n deliminated list to compare file names against
-o \t Output file, will be overwritten" 1>&2
}

  compDir='2'
  compFile='2'
  outFile='2'
  OPTIND=1
  
  while getopts ":d:i:o:h" opt; do
    case $opt in
      d)
        if [[ -d "$OPTARG" && -r "$OPTARG" ]]; then
        # Argument is a readable directory
          compDir="$OPTARG"
        else
          echo "-d argument is not a directory, or not readable: $OPTARG" >&2
          compareListToFiles_usage && return 2
        fi
        ;;
      i)
        if [[ -f "$OPTARG" && -s "$OPTARG" && -r "$OPTARG" ]]; then
        # File is a regular, non-empty, readable file
           compFile="$OPTARG"
        else
          echo "-i agument is not readable, does not contain data, or is not a file: $OPTARG" >&2
          compareListToFiles_usage && return 2
        fi
        ;;
      o)
        if [ ! -w "$OPTARG" ]; then
        # File exists, but cannot be written to.
          echo "Cannot write to: $OPTARG" >&2
          compareListToFiles_usage && return 2
        elif [ -e "$OPTARG" ]; then
          rm "$OPTARG" && touch "$OPTARG" \
            || (echo "Failed to clean up: $OPTARG" >&2 && compareListToFiles_usage && return 2)
          outFile="$OPTARG"
        fi
        ;;
      h)
        compareListToFiles_usage
        ;;
      ?)
        echo "Invalid option: -$OPTARG" >&2
        ;;
      :)
        echo "Argument missng to: -$OPTARG" >&2
        ;;
      *)
        #Default match all, do nothing
        ;;
    esac
  done

  # Halt if all required input has not been declared
  [[ "$compDir" = '2' || "$compFile" = '2' || "$outFile" = '2' ]] && compareListToFiles_usage && return 1
  
  
  #Generate list of files (no path), store in temp
  #find . -depth >> /tmp/compareListToFiles
  #for i in $(find . -depth); do basename $i; done | sort >> /tmp/compareListToFiles
  
  # Strip extensions, year tags, special characters, replace '-', '_', or '.' with spaces; fix multiple spaces
  #sed -r 's/\..{3,4}$//;s/[(][0-9]{4}[)]$//;s/[-_.]/ /g;s/[^A-Za-z0-9 ]//g;s/  +/ /g'
}