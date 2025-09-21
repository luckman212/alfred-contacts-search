#!/bin/zsh --no-rcs

# thanks @FireFingers21 for inspiration
# https://www.alfredforum.com/topic/16269-contacts-search-only-with-keyword/page/2/#findComment-122641

# requires jq: brew install jq

BASE_DIR="$HOME/Library/Application Support/AddressBook/Sources"
ADBK_DB='AddressBook-v22.abcddb'

while read -r DB ; do sqlite3 -json "$DB" <<EOF

SELECT
    '$DB' as DB,
    r.ZTITLE,
    r.ZFIRSTNAME,
    r.ZMIDDLENAME,
    r.ZLASTNAME,
    r.ZNICKNAME,
    r.ZORGANIZATION,
    r.ZJOBTITLE,
    r.ZUNIQUEID,
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

done < <(find "$BASE_DIR" -type f -name "$ADBK_DB" -depth 2) |

jq \
    --null-input \
    --compact-output \
    --arg dbname "$ADBK_DB" \
    --argjson ct ${CACHE_SECS:-10} '

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
                    .dbpath = (.DB | sub($dbname; "")) |
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
                    .filename = "\(.dbpath)/Metadata/\(.ZUNIQUEID).abcdp" |
                    .match = .ZSTRINGFORINDEXING |
                    {
                        uid: .ZUNIQUEID,
                        match: .match,
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
                ) | sort_by(.title // "<No name>" | trim_i | ascii_downcase)
            else
                [{ title: "No contacts found", valid: false }]
            end
        )
    }'
