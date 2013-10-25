# To use: add a .jira-url file in the base of your project
#
# Setup:
#   cd to/my/project
#   echo "https://name.jira.com" >> .jira-url
# Usage:
#   jira          # if current git branch has a valid JIRA ticket syntax
#                 #   opens the current git branch in JIRA
#                 # otherwise
#                 #   opens a new issue
#   jira new      # opens a new issue
#   jira ABC-123  # opens an existing issue

jira () {
  if [ -f .jira-url ]; then
    jira_url=$(cat .jira-url)
  else
    echo "JIRA url is not specified anywhere."
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
  else
    # open the specified issue
    echo "Opening ticket '$1' in JIRA."
    open $jira_url/browse/$1
  fi
}
