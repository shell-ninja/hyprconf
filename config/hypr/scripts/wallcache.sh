#!/usr/bin/env sh
# wallcache.sh — Generate thumbnail, blur, and quad images for the current wallpaper.

cacheDir="$HOME/.config/hypr/.cache"
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

    # Generate blurred image (only if missing)
    [ ! -e "${thmbDir}/${wall_name}.blur" ] && \
        magick "${x_wall}[0]" -strip -scale 70% -blur 0x10 -resize 100% \
        "${thmbDir}/${wall_name}.blur"

    # Generate quad image (only if missing)
    [ ! -e "${thmbDir}/${wall_name}.quad" ] && \
        magick "${thmbDir}/${wall_name}.sqre" \
        \( -size 500x500 xc:white -fill "rgba(0,0,0,0.7)" \
           -draw "polygon 400,500 500,500 500,0 450,0" \
           -fill black \
           -draw "polygon 500,500 500,0 450,500" \) \
        -alpha Off -compose CopyOpacity -composite \
        "${thmbDir}/${wall_name}.quad"

    # Copy blur and quad to cache root (plain cp — no -r needed for files)
    cp "${thmbDir}/${wall_name}.blur" "${cacheDir}/wall.blur"
    cp "${thmbDir}/${wall_name}.quad" "${cacheDir}/wall.quad"
}

fn_wallcache "${currentWall_name}" "${input_file}"

[ ! -f "${thmbDir}/${currentWall_name}.quad" ] && exit 1

exit 0
