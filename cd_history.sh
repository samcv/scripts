#!/usr/bin/bash
# Add this to your ~/.bashrc file
# Will save the history of directories you `cd` into. Type back to go back to
# the previously cd'd directory. Back again to go to the cd'd directory before
# that etc. etc.
save_loc () {
	if [ "${BACK_DIR[$(($BACK_NUM + 0))]}" == "" ]; then
		BACK_DIR[$BACK_NUM]="$(pwd)"
	fi
}
alias tell_me='echo ${BACK_DIR[ $(($BACK_NUM - 0)) ]}'
alias cd='BACK_DIR[$BACK_NUM]="$(pwd)"; let "BACK_NUM++"; builtin cd'
alias tell='echo "History $(( $BACK_NUM + 0 )) Future $((${#BACK_DIR[@]} - $BACK_NUM - 0)) Prev dir: ${BACK_DIR[ $(($BACK_NUM - 1 )) ]} Next dir: ${BACK_DIR[$(($BACK_NUM + 1))]}"'
alias back='if [ "$BACK_NUM" -ge "0" ]; then save_loc; let "BACK_NUM--"; builtin cd "${BACK_DIR[$BACK_NUM]}"; else echo "Can'\''t go back any further"; fi'
alias next='if [ ! "${BACK_DIR[$(($BACK_NUM + 1))]}" == "" ]; then builtin cd "${BACK_DIR[ $(( $BACK_NUM + 1 )) ]}"; let "BACK_NUM++"; else echo "Can'\''t go forward any further"; fi'
BACK_NUM=0
