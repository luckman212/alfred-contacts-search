#!/bin/zsh --no-rcs

# for Tahoe 26.4+ because abcdp metadata files no longer seem to get created

abcdp=$1
base=$abcdp:t
base_noext=${base%.abcdp}
url="$base_noext?unify=YES"

if [[ ! -f $abcdp ]]; then
  print -r "generating .abcdp metadata placeholder" >&2
  metadata_dir=$abcdp:h
  if [[ $metadata_dir:t == "Metadata" ]]; then
    mkdir -p "$metadata_dir"
    touch "$abcdp"
  else
    print -r "unexpected arg: $abcdp" >&2
    exit 1
  fi
fi

#emit JSON
cat <<EOJ
{
  "alfredworkflow": {
    "arg": "$abcdp",
    "variables": {
      "CONTACTS_ACTION": "$CONTACTS_ACTION",
      "CONTACTS_URL": "$url",
      "ORIG_ARG": "$abcdp"
    }
  }
}
EOJ
