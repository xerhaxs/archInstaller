#!/bin/bash

LOCALE_FILE="locale.gen"

LOCALE_OPTIONS=()
LOCALE_LINE_COUNT=0
while IFS= read -r LINE
do
    ((LOCALE_LINE_COUNT++))
    if [ $LOCALE_LINE_COUNT -le 17 ] ; then
        continue
    fi

    # Prüfen, ob die Zeile mit einem # beginnt
    if [[ "$LINE" == "#"* ]] ; then
        # Option mit "off" hinzufügen
        LOCALE_OPTIONS+=("${LINE:1}" "" off)
    else
        # Option mit "on" hinzufügen
        LOCALE_OPTIONS+=("$LINE" "" on)
    fi
done < "$LOCALE_FILE"

# Whiptail-Checkliste anzeigen und Auswahl speichern
CHOOSEN_LOCALS=$(whiptail --title "Textoptionen" --checklist "Wählen Sie die gewünschten Optionen:" 15 50 5 "${LOCALE_OPTIONS[@]}" 3>&1 1>&2 2>&3)

# Ausgewählte Optionen ausgeben
echo "Sie haben folgende Optionen ausgewählt: $CHOOSEN_LOCALS"

LOCALE_TMP=$(mktemp)

# Neue locale.gen Zeilen schreiben
LOCALE_LINE_COUNT=0
while IFS= read -r LINE
do
    ((LOCALE_LINE_COUNT++))
    if [ $LOCALE_LINE_COUNT -le 17 ] ; then
        echo "$LINE" >> "$LOCALE_TMP"
        continue
    fi

    if [[ "$LINE" == "#"* ]] ; then
        if echo "${CHOOSEN_LOCALS[@]}" | grep -qF "${LINE:1}" ; then
            sed -e "s/^$LINE$/${LINE/"#"/}/" >> "$LOCALE_TMP"
            #sed -e "/^$LINE/s/^#//" >> "$LOCALE_TMP"
            # sed -e "/^$ZEILE/s/^#//" "$DATEI" > "$TMP"
        else
            echo "${LINE}" >> "$LOCALE_TMP"
        fi
    else
        if echo "${CHOOSEN_LOCALS[@]}" | grep -qi "${LINE}" ; then
            echo "${LINE}" >> "$LOCALE_TMP"
        else
            echo "#${LINE}" >> "$LOCALE_TMP"
        fi
    fi
done < "$LOCALE_FILE"

# Kopieren des temporären Textdateiinhalts in Originaldatei
cp "$LOCALE_TMP" "$LOCALE_FILE"

# Ausgewählte Optionen ausgeben
echo "Die Datei $LOCALE_FILE wurde aktualisiert."

# Bereinigung
rm "$LOCALE_TMP"