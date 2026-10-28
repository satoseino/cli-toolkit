_toolkit_complete() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "-h --help -V --version start-ts-cdk-project start-python-project start-go-project" -- "$cur") )
        return 0
    fi

    # Every scaffold flag takes a free-text value, and so does the
    # positional argument, so only flag names are ever completed.
    local flags
    case "${COMP_WORDS[1]}" in
        start-ts-cdk-project)
            flags="-h --help --eslint-version --eslint-js-version --typescript-eslint-version --vitest-version --vitest-coverage-v8-version --aws-cdk-cli-version --aws-cdk-lib-version --constructs-version --esbuild-version --prettier-version --tsx-version --typescript-version --aws-cdk-assert-version --yaml-version --gelato-version --nodejs-version --timeout-seconds"
            ;;
        start-python-project)
            flags="-h --help --description --gelato-version --shell-cmd-on-change-version --ruff-version --mypy-version --pytest-version --pytest-mock-version --pytest-cov-version --sphinx-version --python-version --timeout-seconds"
            ;;
        start-go-project)
            flags="-h --help --go-version --golangci-lint-version --gelato-version --timeout-seconds"
            ;;
        *)
            return 0
            ;;
    esac

    # No completion for the value of a flag, given as "--flag value" or
    # "--flag=value" (bash splits the latter at "=").
    case "$prev" in
        -h|--help)
            ;;
        --*|=)
            return 0
            ;;
    esac

    case "$cur" in
        -*)
            COMPREPLY=( $(compgen -W "$flags" -- "$cur") )
            ;;
    esac

    return 0
}

complete -F _toolkit_complete toolkit

# vim: set ft=sh :
