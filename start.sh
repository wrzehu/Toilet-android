#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_DIR="$SCRIPT_DIR"
SANDBOX_PROFILE="$PROJECT_DIR/agent-sandbox.sb"

# 1. Sprawdzenie obecności profilu piaskownicy
if [ ! -f "$SANDBOX_PROFILE" ]; then
    echo "BŁĄD: Nie odnaleziono pliku profilu piaskownicy: $SANDBOX_PROFILE" >&2
    exit 1
fi

# 2. Uzupełnienie zmiennej PATH o typowe lokalizacje instalacji Antigravity CLI
export PATH="$HOME/.gemini/antigravity/bin:$HOME/Library/Application Support/Antigravity/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# 3. Wyszukanie binarnego pliku agy / antigravity
find_agy_binary() {
    if command -v agy >/dev/null 2>&1; then
        command -v agy
    elif command -v antigravity >/dev/null 2>&1; then
        command -v antigravity
    elif [ -x "$HOME/.gemini/antigravity/bin/agy" ]; then
        echo "$HOME/.gemini/antigravity/bin/agy"
    elif [ -x "$HOME/.gemini/antigravity/bin/antigravity" ]; then
        echo "$HOME/.gemini/antigravity/bin/antigravity"
    elif [ -x "$HOME/Library/Application Support/Antigravity/bin/agy" ]; then
        echo "$HOME/Library/Application Support/Antigravity/bin/agy"
    elif [ -x "$HOME/Library/Application Support/Antigravity/bin/antigravity" ]; then
        echo "$HOME/Library/Application Support/Antigravity/bin/antigravity"
    elif [ -x "/opt/homebrew/bin/agy" ]; then
        echo "/opt/homebrew/bin/agy"
    elif [ -x "/usr/local/bin/agy" ]; then
        echo "/usr/local/bin/agy"
    else
        echo "agy"
    fi
}

AGY_BIN="$(find_agy_binary)"

# 4. Tryb bezpośredni (uruchomienie piaskownicy w bieżącej powłoce)
if [ "$1" = "--direct" ] || [ "$1" = "-d" ]; then
    shift
    echo "============================================================"
    echo "  Antigravity CLI Sandbox (macOS sandbox-exec)"
    echo "  Katalog projektu: $PROJECT_DIR"
    echo "  Profil:          $SANDBOX_PROFILE"
    echo "  Polecenie:       $AGY_BIN"
    echo "============================================================"
    echo ""

    if ! command -v sandbox-exec >/dev/null 2>&1; then
        echo "BŁĄD: Narzędzie 'sandbox-exec' nie jest dostępne w tym systemie." >&2
        exit 1
    fi

    # Uruchomienie sandbox-exec z przekazaniem parametrów ścieżek
    set +e
    sandbox-exec -D PROJECT_DIR="$PROJECT_DIR" -D HOME_DIR="$HOME" -f "$SANDBOX_PROFILE" "$AGY_BIN" "$@"
    STATUS=$?
    set -e

    if [ $STATUS -ne 0 ]; then
        echo ""
        echo "Antigravity CLI zakończyło działanie z kodem $STATUS."
        echo "Naciśnij Enter, aby zamknąć..."
        read -r _
    fi
    exit $STATUS
fi

# 5. Tryb domyślny: uruchomienie nowej sesji w aplikacji Terminal.app
echo "Otwieranie nowej sesji Antigravity CLI w Terminal.app..."

# Przygotowanie bezpiecznego polecenia dla Terminal.app
CMD="cd $(printf '%q' "$PROJECT_DIR") && $(printf '%q' "$PROJECT_DIR/start.sh") --direct"
for arg in "$@"; do
    CMD="$CMD $(printf '%q' "$arg")"
done

# Otwarcie okna Terminal.app przez AppleScript (lub fallback na bieżący terminal)
osascript -e "tell application \"Terminal\" to do script \"$CMD\"" \
          -e "tell application \"Terminal\" to activate" 2>/dev/null || {
    echo "Ostrzeżenie: Nie udało się uruchomić Terminal.app przez AppleScript. Przełączanie na tryb bezpośredni..."
    exec "$PROJECT_DIR/start.sh" --direct "$@"
}

echo "Sesja została pomyślnie uruchomiona w osobnym oknie Terminal.app."
