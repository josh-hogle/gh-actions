# join_by joins an array with a multi-character delimiter
join_by() {
	local d=$1
	shift
	echo -n "$1"
	shift
	printf "%s" "${@/#/$d}";
}

# setup colors
NORMAL="\[\033[0m\]"
BLUE="\[\033[0;34m\]"
GREEN="\[\033[0;32m\]"
CYAN="\[\033[0;36m\]"
RED="\[\033[0;31m\]"
PURPLE="\[\033[0;35m\]"
BROWN="\[\033[0;33m\]"
LT_GRAY="\[\033[0;37m\]"
DK_GRAY="\[\033[1;30m\]"
LT_BLUE="\[\033[1;34m\]"
LT_GREEN="\[\033[1;32m\]"
LT_CYAN="\[\033[1;36m\]"
LT_RED="\[\033[1;31m\]"
LT_PURPLE="\[\033[1;35m\]"
YELLOW="\[\033[1;33m\]"
WHITE="\[\033[1;37m\]"

# setup environment
env=("${BLUE}docker${NORMAL}")
if [ ! -z "${IMAGE_NAME}" ]; then
	env+=("${BROWN}${IMAGE_NAME}${NORMAL}")
fi
if [ ! -z "${CONTAINER_NAME}" ]; then
	env+=("${GREEN}${CONTAINER_NAME}${NORMAL}")
fi
env=$(join_by '|' "${env[@]}")

# setup prompt
if [ -z "$USER" -o "$USER" == "root" ]; then
	PS1="${NORMAL}[${env}] ${LT_PURPLE}\h${NORMAL}:${LT_CYAN}\w${NORMAL}\n${LT_RED}\u #${NORMAL} "
else
	PS1="${NORMAL}[${env}] ${LT_PURPLE}\h${NORMAL}:${LT_CYAN}\w${NORMAL}\n${LT_GREEN}\u \$${NORMAL} "
fi
