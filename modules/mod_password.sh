#!/usr/bin/env bash

run_password_checker() {
    clear
    echo "================================================="
    echo "       MODULE: Password Strength Checker         "
    echo "================================================="

    read -s -p "Enter password to test: " PASSWORD
    echo

    local LENGTH=${#PASSWORD}
    local SCORE=0
    local FEEDBACK=()

    # 1. Length check
    if (( LENGTH >= 8 )); then
        ((SCORE++))
    else
        FEEDBACK+=("Password is too short (min 8 characters)")
    fi

    if (( LENGTH >= 12 )); then
        ((SCORE++))
    fi

    # 2. Lowercase letters
    if [[ "$PASSWORD" =~ [a-z] ]]; then
        ((SCORE++))
    else
        FEEDBACK+=("Add lowercase letters")
    fi

    # 3. Uppercase letters
    if [[ "$PASSWORD" =~ [A-Z] ]]; then
        ((SCORE++))
    else
        FEEDBACK+=("Add uppercase letters")
    fi

    # 4. Digits
    if [[ "$PASSWORD" =~ [0-9] ]]; then
        ((SCORE++))
    else
        FEEDBACK+=("Add numbers")
    fi

    # 5. Special characters
    if [[ "$PASSWORD" =~ [^a-zA-Z0-9] ]]; then
        ((SCORE++))
    else
        FEEDBACK+=("Add special characters (!@#\$%^&*)")
    fi

    # 6. Common dictionary lookup
    local COMMON=("password" "123456" "qwerty" "admin" "letmein" "welcome" "monkey" "dragon")
    for weak in "${COMMON[@]}"; do
        if [[ "$PASSWORD" == "$weak" ]]; then
            SCORE=0
            FEEDBACK+=("This is a commonly used password! Choose a different one.")
            break
        fi
    done

    # Output Presentation
    echo "-------------------------------------------------"
    echo -n "Masked: "
    printf '*%.0s' $(seq 1 "$LENGTH")
    echo
    echo "Length: $LENGTH | Score: $SCORE / 6"
    echo "-------------------------------------------------"

    if (( SCORE <= 2 )); then
        echo -e "\033[0;31mStrength: WEAK ❌\033[0m"
    elif (( SCORE <= 4 )); then
        echo -e "\033[1;33mStrength: MEDIUM ⚠️\033[0m"
    else
        echo -e "\033[0;32mStrength: STRONG ✅\033[0m"
    fi

    if [[ ${#FEEDBACK[@]} -gt 0 ]]; then
        echo -e "\nRecommendations:"
        for suggestion in "${FEEDBACK[@]}"; do
            echo "  - $suggestion"
        done
    fi

    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

# If executed directly:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_password_checker
fi
