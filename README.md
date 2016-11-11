## bash-history-archive.pl
A program to archive bash history from `~/.bash_history` in files by date.

By default it archives to files files in `~/bash-history/YYYY-MM-DD-bash_history.txt` for the date in which the commands were run in bash.  It will also write to a file called `~/bash-history/last-archive-date` with the last date of backup to ensure only bash history items that have occured since the last run of `bash-history-archive.pl` are archived.

For this to work you will need to add the following to your `~/.bashrc`

    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

    HISTTIMEFORMAT="%d/%m/%y  %T "


## kexec-prepare.sh
A script to automate kexec, which allows rebooting without having to go to BIOS or do a POST.  More details on [kexec here](http://linux.die.net/man/8/kexec).

    Usage: kexec-prepare.sh <kernel-name> <option>
No option implies to reuse the current command line options.
The -g option will read the kernel command line options in /etc/default/grub
and append to it the root filesystem that is currently mounted at '/'
This script checks to make sure the kernel and initrd exist before issuing the command to `kexec`.
