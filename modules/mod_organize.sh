#!/usr/bin/env bash

run_file_organizer() {
    clear
    echo "================================================="
    echo "          MODULE: Automated File Organizer       "
    echo "================================================="

    read -rp "Enter target directory path [Default: $HOME/Downloads]: " TARGET_DIR
    TARGET_DIR="${TARGET_DIR:-$HOME/Downloads}"

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo -e "\033[0;31m[-] Error: Directory '$TARGET_DIR' does not exist.\033[0m"
        read -rp "Press [Enter] to return to menu..."
        return 1
    fi

    mkdir -p "$TARGET_DIR"/{Images,Documents,Videos,Music,Archives,Others}

    local count=0
    for file in "$TARGET_DIR"/*; do
        [[ -f "$file" ]] || continue

        local ext="${file##*.}"
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        case "$ext" in
            jpg|jpeg|png|gif|bmp|svg|webp)
                mv "$file" "$TARGET_DIR/Images/" ;;
            pdf|doc|docx|txt|odt|xls|xlsx|ppt|pptx|csv)
                mv "$file" "$TARGET_DIR/Documents/" ;;
            mp4|mkv|avi|mov|wmv|flv|webm)
                mv "$file" "$TARGET_DIR/Videos/" ;;
            mp3|wav|flac|aac|ogg|m4a)
                mv "$file" "$TARGET_DIR/Music/" ;;
            zip|tar|gz|bz2|xz|7z|rar)
                mv "$file" "$TARGET_DIR/Archives/" ;;
            *)
                mv "$file" "$TARGET_DIR/Others/" ;;
        esac
        ((count++))
    done

    echo -e "\033[0;32m[+] Successfully organized $count file(s) into category subfolders in:\033[0m"
    echo "    $TARGET_DIR"
    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_file_organizer
fi
