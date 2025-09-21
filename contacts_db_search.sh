#!/bin/zsh --no-rcs

# thanks @FireFingers21 for inspiration
# https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword/page/2/#findComment-122641

# requires jq: brew install jq

_dbg() {
	(( DEBUG == 1 )) || return 0
	cat >&2 <<-EOF
	🪵DEBUG: $1
	EOF
}

_get_dbs() {
	if [[ -z $EXCLUDED_GUIDS ]]; then
		_dbg "no exclusions"
		find "$BASE_DIR" -type f -name "$ADBK_DB" -maxdepth 2
	else
		_dbg "excluded GUIDs:${CR}${EXCLUDED_GUIDS}"
		find "$BASE_DIR" -type f -name "$ADBK_DB" -maxdepth 2 |
		grep --ignore-case --invert-match --fixed-strings --file <(echo "$EXCLUDED_GUIDS")
	fi
}

_dbg "${0:t} script started"

ADBK_DB='AddressBook-v22.abcddb'
CR=$'\n'
if [[ -z $BASE_DIR ]]; then
	BASE_DIR="$HOME/Library/Application Support/AddressBook/Sources"
	_dbg "using DEFAULT sources dir: $BASE_DIR"
else
	_dbg "using CUSTOM sources dir: $BASE_DIR"
fi

_dbg "sort order: $SORT_BY"

while read -r DB ; do
	(( c++ ))
	SOURCE_DIR=${DB:A:h}
	_dbg "processing source $c: $SOURCE_DIR"
	sqlite3 -json "$DB" <<-EOF
	SELECT
		'$SOURCE_DIR' as DBPATH,
		r.ZTITLE,
		r.ZFIRSTNAME,
		r.ZMIDDLENAME,
		r.ZLASTNAME,
		r.ZNICKNAME,
		r.ZORGANIZATION,
		r.ZJOBTITLE,
		r.ZUNIQUEID,
		r.ZMODIFICATIONDATE,
		i.ZSTRINGFORINDEXING
	FROM
		ZABCDRECORD r
	LEFT JOIN
		ZABCDCONTACTINDEX i ON i.ZCONTACT = r.Z_PK
	WHERE
		r.ZCONTACTINDEX IS NOT NULL
	GROUP BY
		r.ZUNIQUEID;
	EOF
done < <(_get_dbs) |

jq \
	--null-input \
	--compact-output \
	--arg dbname "$ADBK_DB" \
	--arg sortby "$SORT_BY" \
	--argjson ct ${CACHE_SECS:-60} '

	def join_nonempty(sep):
		map(select(.)) | join(sep);
	def join_nonempty:
		join_nonempty(" ");
	def trim_i:
		sub("^\\s+";"") | sub("\\s+$";"");

	[inputs] | reduce .[] as $item ([]; . + $item) |

	{
		cache: { seconds: $ct, loosereload: true },
		skipknowledge: true,
		items: (
			if length > 0 then
				map(
					.name = ([ .ZFIRSTNAME, .ZMIDDLENAME, .ZLASTNAME ] | join_nonempty) |
					if .ZJOBTITLE then
						if (.name | length > 0) then
							.name += " (\(.ZJOBTITLE))"
						else
							.name = .ZJOBTITLE
						end
					end |
					if (.name | length > 0) then
						.title = ([ .name, .ZORGANIZATION ] | join_nonempty(" - ")) |
						.type = "person"
					else
						.title = .ZORGANIZATION |
						.type = "org"
					end |
					.filename = "\(.DBPATH)/Metadata/\(.ZUNIQUEID).abcdp" |
					{
						uid: .ZUNIQUEID,
						mod: .ZMODIFICATIONDATE,
						match: .ZSTRINGFORINDEXING,
						title: .title,
						arg: .filename,
						icon: { path: "\(.type).png" },
						text: {
							copy: .title,
							largetype: .title
						},
						action: { text: .title },
						quicklookurl: .filename
					}
				) |
				if $sortby == "date" then
					sort_by(-.mod)
				else
					sort_by(.title // "<No name>" | trim_i | ascii_downcase)
				end
			else
				[{ title: "No contacts found", valid: false }]
			end
		)
	}'

_dbg "${0:t} script finished"
