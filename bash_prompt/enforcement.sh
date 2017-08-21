#!/bin/bash

print_warning()
{
    local hint=${1}
    local RED="\033[0;31m"
    local COLOROFF="\033[0m"
    echo -e "${RED}"
    echo -e " _________________________\n( ${hint} )\n -------------------------"
    echo -e "        o   ^__^ "
    echo -e "         o  (oo)\_______ "
    echo -e "            (__)\       )\/\ "
    echo -e "                ||----w | "
    echo -e "                ||     || "
    echo -e "${COLOROFF}"
}

droppyc()
{
    find ${REPO_BASE_PATH} -name "*.pyc" -exec rm -rf {} \;
}

pull()
{
    local regx=$1
    local branch=$2
    local loc=$(pwd)
    for prepo in $(ls "${REPO_BASE_PATH}" | grep -i "${regx}"); do
        cd "${REPO_BASE_PATH}/${prepo}"
        echo -e "> switch to repo: $(pwd)..."
        local cur=$(git branch | grep '\*' | cut -d ' ' -f 2)
        if [ "${cur}" != "${branch}" ]; then
            git checkout "${branch}" > /dev/null
        fi
        echo -e "> git pull origin ${branch}..." && git pull origin "${branch}"
        if [ "${cur}" != "${branch}" ]; then
            git checkout "${cur}" > /dev/null
        fi
        echo
    done
    cd $loc
}

safe_rebase()
{
    local target_branch=$1
    start_info=$(git rebase ${target_branch})
    if [[ "${start_info}" == *"Fast-forwarded"* ]] || [[ "${start_info}" == *"up to date"* ]]; then
        echo -e "${start_info}"
        return
    fi
    echo -e "${start_info}\n" && echo -e "START:\n"
    while IFS=, read -p "CMD > " CMD; do
        if [ "${CMD}" == "q" ] || [ "${CMD}" == "quit" ]; then
            read -p "CMD > Abort Rebase[y/N]?" option
            if [ "${option}" == "y" ]; then
                git rebase --abort
            fi
            break
        fi
        if [[ "${CMD}" == *"commit"* ]]; then
            print_warning "Hmm, don't commit here"
            continue
        fi
        eval ${CMD}
        echo
    done
}

mysqlcon()
{
    local appid=${1}
    local environ=${2}
    declare -i port
    while IFS=: read app env username passwd host port dbname; do
        if [ "${appid}" == "${app}" ] && [ "${environ}" == "${env}" ]; then
            break
        fi
    done < "${MYSQL_CON_CFG_PATH}"
    mycli -u"${username}" -p"${passwd}" -h "${host}" -P ${port} -D"${dbname}"
}

sshdev()
{
    local appid=${1}
    local environ=${2}
    while IFS=: read app env username host private_key; do
        if [ "${appid}" == "${app}" ] && [ "${environ}" == "${env}" ]; then
            break
        fi
    done < "${SSH_DEV_CFG_PATH}"
    if [ -z "${private_key}" ]; then
        ssh "${username}"@"${host}"
    else
        ssh "${username}"@"${host}" -i "${private_key}"
    fi
}

proxychains()
{
    proxychains4 -f $HOME/.config/proxychains/proxychains.conf "$@"
}

installproj()
{
    CFLAGS="-std=c99" pip install -r requirements.txt \
        --extra-index-url http://pypi.dev.elenet.me/eleme/eleme\
        --trusted-host pypi.dev.elenet.me
}

force_reload()
{
    source $HOME/.bash_profile
}
