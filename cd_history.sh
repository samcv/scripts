#!/usr/bin/bash
# Add this to your ~/.bashrc file
# Will save the history of directories you `cd` into. Type back to go back to
# the previously cd'd directory. Back again to go to the cd'd directory before
# that etc. etc.
save_loc () {
	if [ "${BACK_DIR[$(($BACK_NUM + 0))]}" == "" ]  && [ $BACK_NUM -gt 0 ]; then
		BACK_DIR[$BACK_NUM]="$(pwd)"
	fi
}
alias cd='BACK_DIR[$BACK_NUM]="$(pwd)"; let "BACK_NUM++"; builtin cd'
alias tell='if [ ${#BACK_DIR[@]} -ne 0 ]; then echo "History $(( $BACK_NUM + 0 )) Future $((${#BACK_DIR[@]} - $BACK_NUM - 0)) Prev dir: ${BACK_DIR[ $(($BACK_NUM - 1 )) ]} Next dir: ${BACK_DIR[$(($BACK_NUM + 1))]}"; fi;'
alias back='if [ "$BACK_NUM" -gt "0" ]; then save_loc; let "BACK_NUM--"; builtin cd "${BACK_DIR[$BACK_NUM]}"; else echo "Can'\''t go back any further"; fi'
alias next='if [ ! "${BACK_DIR[$(($BACK_NUM + 1))]}" == "" ]; then builtin cd "${BACK_DIR[ $(( $BACK_NUM + 1 )) ]}"; let "BACK_NUM++"; else echo "Can'\''t go forward any further"; fi'
BACK_NUM=0
