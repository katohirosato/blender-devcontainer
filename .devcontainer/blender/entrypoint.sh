#!/usr/bin/env bash
set -e

# check we are running as root
# rootで実行されていることが要求される。
if [ "$(id -u)" -ne 0 ]; then
    echo "fatal: entrypoint.sh script must be run as root (running as $(whoami))"
    exit 1
fi

# set new uid/gid for the non-root user and take ownership of files
# old_uid, old_gid: システム上の $DOCKER_USER のUID GID。
# PUID, PGID: 環境変数で指定された新しいUID GID。
# これらが異なる場合、$DOCKER_USERのUID GIDを変更する。
# さらに、システム上の全てのファイルのうち、$DOCKER_USERが所有しているものを新しいUID GIDに変更する。ただし、/proc, /sys はこの限りではない。
old_uid=$(id -u "$DOCKER_USER")
old_gid=$(id -g "$DOCKER_USER")
if [ "$old_uid" != "$PUID" ] || [ "$old_gid" != "$PGID" ]; then
    echo "Setting uid/gid $PUID:$PGID for user $DOCKER_USER"
    usermod -u "$PUID" "$DOCKER_USER"
    groupmod -g "$PGID" "$DOCKER_USER"
    set +e
    find / -path /proc -prune -o -path /sys -prune -o -uid "$old_uid" -exec chown -h "$PUID" {} +
    find / -path /proc -prune -o -path /sys -prune -o -gid "$old_gid" -exec chown -h :"$PGID" {} +
    set -e
fi

# set new gid for the render group if provided
# old_render_gid: システム上の `docker-render` グループのGID。
# RENDER_GROUP_GID が old_render_gid と異なる場合、docker-render グループの GID を変更する。
old_render_gid=$(getent group docker-render | cut -d: -f3)
if [ -n "$RENDER_GROUP_GID" ] && [ "$old_render_gid" != "$RENDER_GROUP_GID" ]; then
    echo "Setting GID $RENDER_GROUP_GID for group docker-render"
    groupmod -g "$RENDER_GROUP_GID" docker-render
fi

# root ユーザーとして、環境変数を設定する。
# XDG_RUNTIME_DIR: https://wiki.archlinux.jp/index.php/Sway
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$PUID}"
mkdir -p ${XDG_RUNTIME_DIR}
chown ${DOCKER_USER}:${DOCKER_USER} ${XDG_RUNTIME_DIR}
chmod 0755 ${XDG_RUNTIME_DIR}
# WLR_BACKENDS: https://github.com/any1/wayvnc/blob/master/FAQ.md
export WLR_BACKENDS="${WLR_BACKENDS:-headless}"
# WLR_LIBINPUT_NO_DEVICES: https://github.com/any1/wayvnc/blob/master/FAQ.md
export WLR_LIBINPUT_NO_DEVICES="${WLR_LIBINPUT_NO_DEVICES:-1}"
# https://github.com/swaywm/wlroots/blob/master/docs/env_vars.md#wlroots-specific
# export WLR_RENDERER=pixman

# Blender の User Directory を作成する。
# https://docs.blender.org/manual/ja/dev/advanced/blender_directory_layout.html#portable-installation
mkdir -p /workspaces/blender/portable/
chown -R ${DOCKER_USER}:${DOCKER_USER} /workspaces/blender/portable/
chmod -R 0755 /workspaces/blender/portable/

# call main entrypoint as non-root user
exec su "$DOCKER_USER" -c "./entrypoint_user.sh"
