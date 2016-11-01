#!/usr/bin/bash
# Add this to your ~/.bashrc file
# Will save the history of directories you `cd` into. Type back to go back to
# the previously cd'd directory. Back again to go to the cd'd directory before
# that etc. etc.
BACK_NUM=0
alias cd='BACK_DIR[$BACK_NUM]="$(pwd)"; let "BACK_NUM++"; builtin cd'
alias tell='echo "BACKNUM = $BACK_NUM ${BACK_DIR[$BACK_NUM]}"'
alias back='if [ "$BACK_NUM" -gt "0" ]; then let "BACK_NUM--"; builtin cd "${BACK_DIR[$BACK_NUM]}"; else echo "Can'\''t go back any further"; fi'
