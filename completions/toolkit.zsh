#compdef toolkit

_toolkit_start_ts_cdk_project() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show context-sensitive help.]' \
        '--eslint-version[Version of eslint, a dev dependency.]:value: ' \
        '--eslint-js-version[Version of eslint-js, a dev dependency.]:value: ' \
        '--typescript-eslint-version[Version of typescript-eslint, a dev dependency.]:value: ' \
        '--vitest-version[Version of vitest, a test dependency.]:value: ' \
        '--vitest-coverage-v8-version[Version of vitest-coverage, a test dependency.]:value: ' \
        '--aws-cdk-cli-version[Version of the AWS CDK CLI.]:value: ' \
        '--aws-cdk-lib-version[Version of the AWS CDK library.]:value: ' \
        '--constructs-version[Version of the constructs library.]:value: ' \
        '--esbuild-version[Version of esbuild, a dev dependency.]:value: ' \
        '--prettier-version[Version of prettier, a dev dependency.]:value: ' \
        '--tsx-version[Version of tsx, a dev dependency.]:value: ' \
        '--typescript-version[Version of typescript.]:value: ' \
        '--aws-cdk-assert-version[Version of aws-cdk-assert, a test dependency.]:value: ' \
        '--yaml-version[Version of yaml, a test dependency.]:value: ' \
        '--gelato-version[Version of gelato, a pre-commit hook.]:value: ' \
        '--nodejs-version[Only accept major and minor version, i.e. the X.Y format.]:value: ' \
        '--timeout-seconds[Timeout scaffolding after this many seconds.]:value: ' \
        '1:project name: '
}

_toolkit_start_python_project() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show context-sensitive help.]' \
        '--description[Short description of the project]:value: ' \
        '--gelato-version[Version of gelato, a pre-commit hook.]:value: ' \
        '--shell-cmd-on-change-version[Version of shell-cmd-on-change, a post-merge hook.]:value: ' \
        '--ruff-version[Version of ruff, a linting dependency.]:value: ' \
        '--mypy-version[Version of mypy, a linting dependency.]:value: ' \
        '--pytest-version[Version of pytest, a test dependency.]:value: ' \
        '--pytest-mock-version[Version of pytest-mock, a test dependency.]:value: ' \
        '--pytest-cov-version[Version of pytest-cov, a test dependency.]:value: ' \
        '--sphinx-version[Version of sphinx, a doc dependency.]:value: ' \
        '--python-version[Python 3 interpreter version. Only accept major and minor version, i.e. the 3.Y format.]:value: ' \
        '--timeout-seconds[Timeout scaffolding after this many seconds.]:value: ' \
        '1:project name: '
}

_toolkit_start_go_project() {
    _arguments \
        '(-h --help)'{-h,--help}'[Show context-sensitive help.]' \
        '--go-version[Will appear in go.mod and GitHub Actions workflow.]:value: ' \
        '--golangci-lint-version[Version of golangci-lint, a pre-commit hook.]:value: ' \
        '--gelato-version[Version of gelato, a pre-commit hook.]:value: ' \
        '--timeout-seconds[Timeout scaffolding after this many seconds.]:value: ' \
        '1:module path: '
}

_toolkit() {
    local -a commands
    commands=(
        'start-ts-cdk-project:Start a TypeScript CDK project in the current directory.'
        'start-python-project:Start a Python project in the current directory.'
        'start-go-project:Start a Go project in the current directory.'
    )

    _arguments -C \
        '(-V --version)'{-V,--version}'[Print the version and exit.]' \
        '(-h --help)'{-h,--help}'[Show context-sensitive help.]' \
        '1: :->command' \
        '*:: :->args' \
        && return 0

    case $state in
        command)
            _describe 'command' commands
            ;;
        args)
            case $words[1] in
                start-ts-cdk-project) _toolkit_start_ts_cdk_project ;;
                start-python-project) _toolkit_start_python_project ;;
                start-go-project) _toolkit_start_go_project ;;
            esac
            ;;
    esac
}

if [ "$funcstack[1]" = "_toolkit" ]; then
    _toolkit "$@"
else
    compdef _toolkit toolkit
fi

# vim: set ft=zsh :
