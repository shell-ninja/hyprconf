#!/usr/bin/env sh
# wallcache.sh — Generate thumbnail, blur, and quad images for the current wallpaper.

cacheDir="$HOME/.hyprconf/hypr/.cache"
thmbDir="${cacheDir}/thumbs"
currentWall_name="$(cat "${cacheDir}/.wallpaper")"
input_file="${cacheDir}/current_wallpaper.png"

mkdir -p "${thmbDir}"

[[ ! -f "${input_file}" ]] && exit 1

fn_wallcache() {
    local wall_name="${1}"
    local x_wall="${2}"

    # Generate square thumbnail (only if missing)
    [ ! -e "${thmbDir}/${wall_name}.sqre" ] && \
        magick "${x_wall}[0]" -strip -thumbnail 500x500^ -gravity center -extent 500x500 \
        "${thmbDir}/${wall_name}.sqre"

    # Generate quad image (only if missing)
    [ ! -e "${thmbDir}/${wall_name}.quad" ] && \
        magick "${thmbDir}/${wall_name}.sqre" \
        \( -size 500x500 xc:white -fill "rgba(0,0,0,0.7)" \
           -draw "polygon 400,500 500,500 500,0 450,0" \
           -fill black \
           -draw "polygon 500,500 500,0 450,500" \) \
        -alpha Off -compose CopyOpacity -composite \
        png:"${thmbDir}/${wall_name}.quad"

    if ! cmp -s "${thmbDir}/${wall_name}.quad" "${cacheDir}/wall.quad"; then
        cp "${thmbDir}/${wall_name}.quad" "${cacheDir}/wall.quad"
    fi

    rm "${thmbDir}/${wall_name}.sqre"
}

fn_wallcache "${currentWall_name}" "${input_file}"

# Notify running island to reload quad wall image
qs ipc -c island call island reloadWallpaper 2>/dev/null || true

[ ! -f "${thmbDir}/${currentWall_name}.quad" ] && exit 1

exit 0
