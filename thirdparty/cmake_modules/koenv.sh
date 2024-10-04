#!/bin/sh

set -eu

[ $# -ge 3 ] && [ $# -le 5 ]

project="$1"
comment="$2"
onlyonce="$3"
shift 3
stamp=''
if [ $# -ne 0 ]; then
    stamp="$1"
    shift
fi
log=''
if [ $# -ne 0 ]; then
    log="$1"
    shift
fi

if [ -n "${CLICOLOR_FORCE:+1}" ] || [ -t 1 ]; then
    export CLICOLOR_FORCE=1
    ANSI_BLUE='\33[34m'
    ANSI_GREEN='\33[32m'
    ANSI_RED='\33[31m'
    ANSI_RESET='\33[0m'
else
    ANSI_BLUE='' ANSI_GREEN='' ANSI_RED='' ANSI_RESET=''
fi

on_exit() {
    code=$?
    # Re-open standard output.
    exec >&3 2>&1
    # Update timestamp on success.
    if [ ${code} -eq 0 ] && [ -n "${stamp}" ]; then
        mkdir -p "${stamp%/*}"
        touch "${stamp}"
    fi
    # Show log on error or verbose mode.
    if [ ${code} -ne 0 ] || [ -n "${KOVERBOSE:+1}" ]; then
        [ -z "${log}" ] || cat "${log}"
    fi
    if [ -n "${GITHUB_ACTIONS:+1}" ]; then
        printf "::endgroup::\n"
    fi
}

err() {
    printf '%bERROR: %s%b\n' "${ANSI_RED}" "$*" "${ANSI_RESET}" 1>&2
}

run() {
    printf '%b+' "${ANSI_BLUE}"
    (exec printf " @PRINTF_QS@" "$@")
    printf '%b\n' "${ANSI_RESET}"
    "$@"
}

validate_md5() { (
    [ $# -ge 2 ] || return 1
    file="$1"
    md5="$2"
    shift 2
    [ -r "${file}" ] || return 1
    calculated="$(md5sum "${file}")"
    calculated="${calculated%% *}"
    if [ "${calculated}" != "${md5}" ]; then
        err "computed checksum did NOT match: ${file}, expected ${md5}, calculated ${calculated}"
        return 1
    fi
); }

download_archive() { (
    [ $# -ge 3 ] || return 1
    dest="$1"
    md5="$2"
    shift 2
    if validate_md5 "${dest}" "${md5}"; then
        return 0
    fi
    for timeout in 0 2 4; do
        sleep ${timeout}
        for url in "$@"; do
            if curl --fail --location --connect-timeout 10 --create-dirs --max-time 30 --retry 3 --output "${dest}" "${url}" && validate_md5 "${dest}" "${md5}"; then
                return 0
            fi
        done
    done
    return 1
); }

extract_archive() { (
    [ $# -eq 2 ] || return 1
    sourcedir="$1"
    archive="$2"
    shift 2
    # Of course `cmake -E tar` does not support `--strip-components=n`,
    # so we need to use a temporary directory and move things around…
    rm -rf "${sourcedir}" "${sourcedir}.tmp" || return 1
    mkdir "${sourcedir}.tmp" || return 1
    oldpwd="${PWD}"
    cd "${sourcedir}.tmp"
    '@CMAKE_COMMAND@' -E tar xf "${archive}"
    root="$(echo *)"
    cd "${oldpwd}"
    mv "${sourcedir}.tmp/${root}" "${sourcedir}"
    rmdir "${sourcedir}.tmp"
); }

apply_patches() { (
    [ $# -ge 1 ] || return 1
    for patch in "$@"; do
        printf '* Applying %s . . .\n' "${patch##*/}"
        patch -p1 --forward --input="${patch}" || return 1
    done
); }

clean_tree() { (
    [ $# -eq 2 ] || return 1
    tree="$1"
    srclist="$2"
    shift 2
    # shellcheck disable=SC2030
    export LANG=C
    killlist="$(list_tree "${tree}" | comm -13 "${srclist}" -)"
    [ -n "${killlist}" ] || return 0
    # Remove files.
    sed -n '/\/$/!p' <<EOF | xargs --delimiter='\n' --no-run-if-empty rm -v || return 1
${killlist}
EOF
    # Remove directories.
    sed -n '/\/$/p' <<EOF | xargs --delimiter='\n' --no-run-if-empty rmdir -v || return 1
${killlist}
EOF
); }

list_tree() { (
    [ $# -ge 1 ] && [ $# -le 2 ] || return 1
    tree="$1"
    shift
    if [ $# -ne 0 ]; then
        exec 1>"$1" || return 1
        shift
    fi
    # shellcheck disable=SC2031
    export LANG=C
    find "${tree}" -type d \( -name '.git' -prune -o -printf '%p/\n' \) -o -printf '%p\n' | sort
); }

generate_depfile() { (
    [ $# -eq 3 ] || return 1
    depfile="$1"
    target="$2"
    srclist="$3"
    shift 3
    exec 1>"${depfile}" || return 1
    printf '%s: \\\n' "${target}"
    sed '/\/$/d;/[~()=]/d;s/[[:space:]\\]/\\&/g;s/\$/$$/g;$!{s/$/ \\/;}' "${srclist}"
); }

clone_git_repo() { (
    [ $# -ge 3 ] || return 1
    repo="$1"
    remote="$2"
    revision="$3"
    shift 3
    clone_depth=50
    mkdir -p "${repo%/*}"
    (
        flock -n 9
        # Try the clone 3 times in case there is an odd git clone issue.
        error=1
        for timeout in 0 2 4; do
            if [ -d "${repo}" ]; then
                error=0
                break
            fi
            sleep ${timeout}
            if git clone --depth ${clone_depth} "${remote}" "${repo}"; then
                error=0
                break
            fi
        done
        if [ ${error} -ne 0 ]; then
            err 'failed to clone repository'
            return 1
        fi
        # Ensure a parent environment variable does not mess up with our git
        # commands, and that git will not try to act on a parent repository.
        # shellcheck disable=SC2030
        export GIT_DIR="${repo}/.git"
        # Enable sparse checkout.
        git -C "${repo}" sparse-checkout init || :
        # Ensure the requested revision is available.
        for attempt in 1 2 3; do
            # Try to checkout it.
            if git -C "${repo}" -c advice.detachedHead=false checkout --force "${revision}" --; then
                # Success!
                break
            fi
            # Failure…
            case ${attempt} in
                1)
                    # Try to fetch only the requested revision.
                    git -C "${repo}" fetch --recurse-submodules=no --depth ${clone_depth} origin "+${revision}:refs/remotes/origin/${revision}" || :
                    ;;
                2)
                    # Try to unshallow the repository.
                    git -C "${repo}" remote rm origin || :
                    # shellcheck disable=SC2015
                    git -C "${repo}" remote add origin "${remote}" && git -C "${repo}" fetch --unshallow --tags || :
                    ;;
                3)
                    # Game over…
                    err 'failed to checkout revision'
                    return 1
                    ;;
            esac
        done
        # Update submodules.
        if ! git -C "${repo}" submodule update --depth ${clone_depth} --force --init --recursive "$@"; then
            err 'failed to update submodules'
            return 1
        fi
        git -C "${repo}" submodule foreach --recursive git sparse-checkout init
    ) 9>"${repo}.lock"
); }

checkout_git_repo() { (
    [ $# -eq 3 ] || return 1
    tree="$1"
    repo="$2"
    revision="$3"
    shift 3
    rm -rf "${tree}" || return 1
    (flock -n 9 && cp -a "${repo}" "${tree}") 9>"${repo}.lock" || return 1
    # Same as above in `checkout_git_repo`.
    # shellcheck disable=SC2031
    export GIT_DIR="${tree}/.git"
    # Note: order matters; trying to `checkout --force` without disabling
    # the sparse-checkouts first will for some reason deinit submodules…
    git -C "${tree}" sparse-checkout disable || return 1
    git -C "${tree}" submodule foreach --recursive git sparse-checkout disable || return 1
    git -C "${tree}" -c advice.detachedHead=false checkout --force --recurse-submodules "${revision}" --
); }

make() { (
    set +u
    unset MAKEOVERRIDES
    MAKEFLAGS="${MAKEFLAGS%% -- *}"
    export MAKEFLAGS
    # shellcheck disable=2086
    exec '@MAKE@' ${PARALLEL_JOBS:+-j}${PARALLEL_JOBS} ${PARALLEL_LOAD:+-l}${PARALLEL_LOAD} "$@"
); }

ninja() { (
    set +u
    NINJA_STATUS="$(printf '      | [%b%s %%p%b] ' "${ANSI_GREEN}" "${project}" "${ANSI_RESET}")"
    export NINJA_STATUS
    # shellcheck disable=2086
    exec '@NINJA@' ${NINJAFLAGS} "$@"
); }

if [ -n "${GITHUB_ACTIONS:+1}" ]; then
    printf "::group::%s\n" "${comment}"
fi

exec 3<&1

trap on_exit EXIT

if [ "${onlyonce}" -ne 0 ] && [ -r "${stamp}" ]; then
    printf '%bSkipping ("only once" step)%b\n' "${ANSI_GREEN}" "${ANSI_RESET}"
    log=''
    exit
fi

if [ -n "${log}" ]; then
    mkdir -p "${log%/*}"
    exec >"${log}" 2>&1
elif [ -z "${CI:+1}${KOVERBOSE:+1}" ]; then
    run() { "$@"; }
fi

# vim: sw=4
