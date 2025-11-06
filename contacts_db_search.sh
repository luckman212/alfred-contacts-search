#!/bin/zsh --no-rcs

# thanks @FireFingers21 for inspiration
# https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword/page/2/#findComment-122641

# may require jq to be installed if you're on macOS < 15: brew install jq

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
		i.ZSTRINGFORINDEXING,
		n.ZTEXT as ZNOTES,
		JSON_GROUP_ARRAY(e.ZADDRESSNORMALIZED) AS EMAIL_ADDRESSES
	FROM
		ZABCDRECORD r
	LEFT JOIN
		ZABCDCONTACTINDEX i ON i.ZCONTACT = r.Z_PK
	LEFT JOIN
		ZABCDEMAILADDRESS e ON e.ZOWNER = r.Z_PK
	LEFT JOIN
		ZABCDNOTE n ON n.ZCONTACT = r.Z_PK
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

	# trim func not included until jq 1.8
	def trim_i:
		sub("^\\s+";"") | sub("\\s+$";"");
	def join_nonempty($sep):
		if type == "array" then
			map(select(. != null) | tostring | select(trim_i | length > 0)) | join($sep)
		else . end;
	def join_nonempty:
		join_nonempty(" ");
	def first_of($default):
		first(.[] | select(type == "string" and . != "" and . != null)) // $default;
	def domains:
		if type == "string" then [.] else . end |
		map(select(type=="string") |
		scan("@.*\\..*";"n")) |
		join(" ");

	[inputs] | reduce .[] as $item ([]; . + $item) |

	{
		cache: { seconds: $ct, loosereload: true },
		skipknowledge: true,
		items: (
			if length > 0 then
				map(
					.name = ([ .ZFIRSTNAME, .ZMIDDLENAME, .ZLASTNAME ] | join_nonempty) |
					if (.name | length > 0) then .type = "person" else .type = "org" end |
					.filename = "\(.DBPATH)/Metadata/\(.ZUNIQUEID).abcdp" |
					.email_arr = (.EMAIL_ADDRESSES | fromjson) |
					.title = ([ ([ .name, .ZORGANIZATION ] | join_nonempty(" - ")), (.email_arr | join(", ")) ] | first_of("<No name>")) |
					if (env.INCLUDE_NOTES? != "1") then .ZNOTES = null end |
					{
						uid: .ZUNIQUEID,
						mod: .ZMODIFICATIONDATE,
						match: ([ .name, .ZORGANIZATION, .ZJOBTITLE, .ZNOTES, (.email_arr | domains), .ZSTRINGFORINDEXING ] | join_nonempty),
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
					sort_by(.title | trim_i | ascii_downcase)
				end
			else
				[{ title: "No contacts found", valid: false }]
			end
		)
	}'

_dbg "${0:t} script finished"
