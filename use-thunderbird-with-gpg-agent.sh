#===========================================================================
#
#          File:  use-thunderbird-with-gpg-agent.sh
# 
#   Description:  Run thunderbird with gpg agent
# 
#       Options:  ---
#  Requirements:  ---
#          Bugs:  ---
#         Notes:  ---
#
#       Version:  1.0
#       Created:  01/14/2014 06:59:00 PM CET
#      Revision:  ---
# 
#         Usage:  ./use-thunderbird-with-gpg-agent.sh 
# 
#        Output:  ---
#
#        Author:  Frank Milde (FM), frank.milde (at) posteo.de
#       Company:  --- 
#
#===========================================================================

#!/bin/sh

envfile="${HOME}/.gnupg/gpg-agent.env"

if test -f "$envfile" && kill -0 $(grep GPG_AGENT_INFO "$envfile" | cut -d: -f 2) 2>/dev/null; then
    eval "$(cat "$envfile")"
else
    eval "$(gpg-agent --daemon --write-env-file "$envfile")"
fi

export GPG_AGENT_INFO  # the env file does not contain the export statement
export SSH_AUTH_SOCK
export SSH_AGENT_PID

/usr/bin/thunderbird
