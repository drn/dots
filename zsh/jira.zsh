# To use: add a .jira-url file in the base of your project
#
# Setup:
#   cd to/my/project
#   echo "https://name.jira.com" >> .jira-url
#   echo "username:password" >> .jira-url
# Usage:
#   jira                    # if current git branch has alid JIRA ticket syntax
#                           #   opens the current git branch in JIRA
#                           # otherwise
#                           #   opens a new issue
#   jira new                # opens a new issue
#   jira ABC-123            # opens an existing issue
#   jira describe ABC-123   # outputs the summary of the ticket
#   jira me                 # outputs the summary of the ticket referenced by
#                           the current branch
#   jira all                # outputs the summaries of all the current branches
#                           # that are in the format of a JIRA ticket
#
# Coming soon:
#   * modularized functionality
#

echoerr() { echo "$@" 1>&2; }

jira () {
  root_path=$(git rev-parse --show-toplevel)
  repo=$(git path $1 | sed 's/.*\///')
  repo=$(
    git remote -v |
    grep origin |
    awk '{print $2}' |
    uniq |
    sed 's/.*\///' |
    sed 's/.git//'
  )

  if [ -f .jira-url ]; then
    jira_url=$(cat $root_path/.jira-url)
  else
    echo "JIRA url is not in $repo's root. Please see setup notes."
    return 0
  fi

  if [ -f .jira-auth ]; then
    jira_auth=$(cat $root_path/.jira-auth)
  else
    echo "JIRA auth is not in $repo's root. Please see setup notes."
    return 0
  fi

  if [ -z "$1" ]; then
    branch="$(git rev-parse --abbrev-ref HEAD)"
    # check if current branch name has a valid JIRA ticket syntax
    if [ "$(echo $branch | grep '^[a-zA-Z]*-[0-9]*$')" ]; then
      echo "Opening ticket '$branch' in JIRA."
      open $jira_url/browse/$branch
    else
      echo "Opening a new ticket in JIRA."
      open $jira_url/secure/CreateIssue!default.jspa
    fi
  elif [ "$1" == "new" ]; then
    # open a new issue
    echo "Creating a new ticket in JIRA."
    open $jira_url/secure/CreateIssue!default.jspa
  elif [ "$1" == "describe" ]; then
    # output the JIRA summary of the specified branch
    content_flag='-H "Content-Type: application/json"'
    endpoint="$jira_url/rest/api/2/issue/$2"
    summary="$(curl -su $jira_auth -X GET $content_flag $endpoint)"
    if [ -z "$2" ]; then
      echo -e "(\033[00;31m...\033[0m)   \033[00;37mIssue not found\033[0m"
    elif [ "$(echo $summary | grep 'Issue Does Not Exist')" ]; then
      echo -e "(\033[00;31m$2\033[0m)   \033[00;37mIssue not found\033[0m"
    else
      summary="$(echo $summary | tr -d '\n')"
      summary="$(echo $summary | sed 's/.*summary"://')"
      summary="$(echo $summary | sed 's/","timetracking.*//')"
      summary="$(echo $summary | sed 's/\\"/"/g')"
      echo -e "(\033[00;31m$2\033[0m)   \033[01;37m$summary\033[0m"
    fi
  elif [ "$1" == "me" ]; then
    # output the JIRA summary of the current branch
    jira describe $(git me)
  elif [ "$1" == "all" ]; then
    git for-each-ref --shell --format='%(refname)' refs/heads |
    while read entry
    do
      branch=`echo $entry | sed 's/.*\///' | sed "s/'//"`
      if [ "$(echo $branch | grep '^[a-zA-Z]*-[0-9]*$')" ]; then
        {jira describe $branch} &
      fi
    done
    wait
  else
    # open the specified issue
    echo "Opening ticket '$1' in JIRA."
    open $jira_url/browse/$1
  fi
}
