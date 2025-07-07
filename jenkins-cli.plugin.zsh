# Autocompletion for jenkins-cli

compdef _jenkins-cli jenkins-cli

__jenkins_cli_debug()
{
    local file="/tmp/jenkins-cli-debug.log"
    if [[ -f "${file}" ]]; then
        echo "$*" >> "${file}"
    fi
}

_jenkins-cli() {
    local state
    local -a commands

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    local lastParam lastChar flagPrefix requestComp out directive comp lastComp noSpace keepOrder
    local -a completions

    __jenkins_cli_debug "state: $state"
    __jenkins_cli_debug "commands: $commands"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}")
    __jenkins_cli_debug "Truncated words[*]: ${words[*]},"

    lastParam=${words[-1]}
    lastChar=${lastParam[-1]}
    __jenkins_cli_debug "lastParam: ${lastParam}, lastChar: ${lastChar}"

    # For zsh, when completing a flag with an = (e.g., oc -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    __jenkins_cli_debug "About to call: eval ${requestComp}"

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)
    __jenkins_cli_debug "completion output: ${out}"

    # Extract the directive integer following a : from the last line
    local lastLine
    while IFS='\n' read -r line; do
        lastLine=${line}
    done < <(printf "%s\n" "${out[@]}")
    __jenkins_cli_debug "last line: ${lastLine}"

    if [ "${lastLine[1]}" = : ]; then
        directive=${lastLine[2,-1]}
        # Remove the directive including the : and the newline
        local suffix
        (( suffix=${#lastLine}+2))
        out=${out[1,-$suffix]}
    else
        # There is no directive specified.  Leave $out as is.
        __jenkins_cli_debug "No directive found.  Setting do default"
        directive=0
    fi

    __jenkins_cli_debug "directive: ${directive}"
    __jenkins_cli_debug "completions: ${out}"
    __jenkins_cli_debug "flagPrefix: ${flagPrefix}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __jenkins_cli_debug "Completion received error. Ignoring completions."
        return
    fi

    local activeHelpMarker="_activeHelp_ "
    local endIndex=${#activeHelpMarker}
    local startIndex=$((${#activeHelpMarker}+1))
    local hasActiveHelp=0

    completions=(
        'add-job-to-view:Adds jobs to view.'
        'apply-configuration:Apply YAML configuration to instance'
        'build:Builds a job, and optionally waits until its completion.'
        'cancel-quiet-down:Cancel the effect of the "quiet-down" command.'
        'check-configuration:Check YAML configuration to instance'
        'clear-queue:Clears the build queue.'
        'connect-node:Reconnect to a node(s)'
        'console:Retrieves console output of a build.'
        'copy-job:Copies a job.'
        'create-credentials-by-xml:Create Credential by XML'
        'create-credentials-domain-by-xml:Create Credentials Domain by XML'
        'create-job:Creates a new job by reading stdin as a configuration XML file.'
        'create-node:Creates a new node by reading stdin as a XML configuration.'
        'create-view:Creates a new view by reading stdin as a XML configuration.'
        'declarative-linter:Validate a Jenkinsfile containing a Declarative Pipeline'
        'delete-builds:Deletes build record(s).'
        'delete-credentials:Delete a Credential'
        'delete-credentials-domain:Delete a Credentials Domain'
        'delete-job:Deletes job(s).'
        'delete-node:Deletes node(s)'
        'delete-view:Deletes view(s).'
        'disable-job:Disables a job.'
        'disable-plugin:Disable one or more installed plugins.'
        'disconnect-node:Disconnects from a node.'
        'enable-job:Enables a job.'
        'enable-plugin:Enables one or more installed plugins transitively.'
        'export-configuration:Export jenkins configuration as YAML'
        'get-credentials-as-xml:Get a Credentials as XML (secrets redacted)'
        'get-credentials-domain-as-xml:Get a Credentials Domain as XML'
        'get-gradle:List available gradle installations'
        'get-job:Dumps the job definition XML to stdout.'
        'get-node:Dumps the node definition XML to stdout.'
        'get-view:Dumps the view definition XML to stdout.'
        'groovy:Executes the specified Groovy script.'
        'groovysh:Runs an interactive groovy shell.'
        'help:Lists all the available commands or a detailed description of single command.'
        'import-credentials-as-xml:Import credentials as XML.'
        'install-plugin:Installs a plugin either from a file, an URL, or from update center.'
        'keep-build:Mark the build to keep the build forever.'
        'list-changes:Dumps the changelog for the specified build(s).'
        'list-credentials:Lists the Credentials in a specific Store'
        'list-credentials-as-xml:Export credentials as XML.'
        'list-credentials-context-resolvers:List Credentials Context Resolvers'
        'list-credentials-providers:List Credentials Providers'
        'list-jobs:Lists all jobs in a specific view or item group.'
        'list-plugins:Outputs a list of installed plugins.'
        'mail:Reads stdin and sends that out as an e-mail.'
        'offline-node:Stop using a node for performing builds temporarily.'
        'online-node:Resume using a node for performing builds.'
        'quiet-down:Quiet down Jenkins, in preparation for a restart.'
        'reload-configuration:Reload everything from file system.'
        'reload-jcasc-configuration:Reload JCasC YAML configuration'
        'reload-job:Reload job(s)'
        'remove-job-from-view:Removes jobs from view.'
        'replay-pipeline:Replay a Pipeline build with edited script.'
        'restart:Restart Jenkins.'
        'restart-from-stage:Restart a completed Declarative Pipeline build from a given stage.'
        'safe-restart:Safe Restart Jenkins.'
        'safe-shutdown:Puts Jenkins into the quiet mode and then shut down.'
        'session-id:Outputs the session ID.'
        'set-build-description:Sets the description of a build.'
        'set-build-display-name:Sets the displayName of a build.'
        'set-external-build-result:Set external monitor job result.'
        'shutdown:Immediately shuts down Jenkins server.'
        'stop-builds:Stop all running builds for job(s)'
        'support:Generates a diagnostic support bundle.'
        'update-credentials-by-xml:Update Credentials by XML'
        'update-credentials-domain-by-xml:Update Credentials Domain by XML'
        'update-job:Updates the job definition XML from stdin.'
        'update-node:Updates the node definition XML from stdin.'
        'update-view:Updates the view definition XML from stdin.'
        'version:Outputs the current version.'
        'wait-node-offline:Wait for a node to become offline.'
        'wait-node-online:Wait for a node to become online.'
        'who-am-i:Reports your credential and permissions.'
    )

   # Add a delimiter after the activeHelp statements, but only if:
    # - there are completions following the activeHelp statements, or
    # - file completion will be performed (so there will be choices after the activeHelp)
    if [ $hasActiveHelp -eq 1 ]; then
        if [ ${#completions} -ne 0 ] || [ $((directive & shellCompDirectiveNoFileComp)) -eq 0 ]; then
            __oc_debug "Adding activeHelp delimiter"
            compadd -x "--"
            hasActiveHelp=0
        fi
    fi

    if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
        __oc_debug "Activating nospace."
        noSpace="-S ''"
    fi

    if [ $((directive & shellCompDirectiveKeepOrder)) -ne 0 ]; then
        __oc_debug "Activating keep order."
        keepOrder="-V"
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local filteringCmd
        filteringCmd='_files'
        for filter in ${completions[@]}; do
            if [ ${filter[1]} != '*' ]; then
                # zsh requires a glob pattern to do file filtering
                filter="\*.$filter"
            fi
            filteringCmd+=" -g $filter"
        done
        filteringCmd+=" ${flagPrefix}"

        __oc_debug "File filtering command: $filteringCmd"
        _arguments '*:filename:'"$filteringCmd"
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        subdir="${completions[1]}"
        if [ -n "$subdir" ]; then
            __oc_debug "Listing directories in $subdir"
            pushd "${subdir}" >/dev/null 2>&1
        else
            __oc_debug "Listing directories in ."
        fi

        local result
        _arguments '*:dirname:_files -/'" ${flagPrefix}"
        result=$?
        if [ -n "$subdir" ]; then
            popd >/dev/null 2>&1
        fi
        return $result
    else
        __oc_debug "Calling _describe"
        if eval _describe $keepOrder "completions" completions $flagPrefix $noSpace; then
            __oc_debug "_describe found some completions"

            # Return the success of having called _describe
            return 0
        else
            __oc_debug "_describe did not find completions."
            __oc_debug "Checking if we should do file completion."
            if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
                __oc_debug "deactivating file completion"

                # We must return an error code here to let zsh know that there were no
                # completions found by _describe; this is what will trigger other
                # matching algorithms to attempt to find completions.
                # For example zsh can match letters in the middle of words.
                return 1
            else
                # Perform file completion
                __oc_debug "Activating file completion"

                # We must return the result of this command, so it must be the
                # last command, or else we must store its result to return it.
                _arguments '*:filename:_files'" ${flagPrefix}"
            fi
        fi
    fi
}

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_jenkins-cli" ]; then
    _jenkins-cli
fi
