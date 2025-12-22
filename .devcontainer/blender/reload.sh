# リポジトリのホットリロード
EXTENSIONS="${EXTENSIONS:-/workspaces/development/extensions/}"
REPOSITORY="${REPOSITORY:-/workspaces/development/repository/}"

update_extension(){
    local EXTENSION="$1"
    if blender/blender --command extension validate "$EXTENSION"; then
        blender/blender --command extension build --source-dir "$EXTENSION" --output-dir "$REPOSITORY"
        blender/blender --command extension server-generate --repo-dir "$REPOSITORY"
        blender/blender --online-mode --command extension remove "$(basename "$EXTENSION")" || true
        blender/blender --online-mode --command extension install --sync --enable "$(basename "$EXTENSION")" || true
        blender/blender --online-mode --command extension sync
        blender/blender --online-mode --command extension update --sync
    fi
}
update_all_extensions(){
    for EXTENSION in "$EXTENSIONS"*; do
        if [ -d "$EXTENSION" ]; then
            local MANIFEST="$EXTENSION/blender_manifest.toml"
            if [ -f "$MANIFEST" ]; then
                update_extension "$EXTENSION"
            fi
        fi
    done
}
init_repository(){
    if [ ! -d "$EXTENSIONS" ]; then
        mkdir -p "$EXTENSIONS"
        chown -R "${DOCKER_USER}:${DOCKER_USER}" "$EXTENSIONS"
        chmod -R 0755 "$EXTENSIONS"
    fi
    if [ ! -d "$REPOSITORY" ]; then
        mkdir -p "$REPOSITORY"
        chown -R "${DOCKER_USER}:${DOCKER_USER}" "$REPOSITORY"
        chmod -R 0755 "$REPOSITORY"
    fi
    if ! blender --command extension repo-list 2>/dev/null | grep -q '^development:'; then
        blender/blender --online-mode --command extension repo-add --name development --url "file://${REPOSITORY}index.json" --source USER development
    fi
    update_all_extensions
}
watch(){
    inotifywait -m -r -e moved_to -e close_write -e delete --format '%w%f %e' "$EXTENSIONS" |
    while read -r path event; do
        update_all_extensions &
    done
}
start_hotreload(){
    init_repository
    watch &
    watch_pid=$!
}