# Every scaffold flag and positional argument is free text, so nothing
# completes values or files.
complete -c toolkit -f

# Root command: subcommands and global flags.
complete -c toolkit -n '__fish_use_subcommand' -a start-ts-cdk-project -d 'Start a TypeScript CDK project in the current directory.'
complete -c toolkit -n '__fish_use_subcommand' -a start-python-project -d 'Start a Python project in the current directory.'
complete -c toolkit -n '__fish_use_subcommand' -a start-go-project -d 'Start a Go project in the current directory.'
complete -c toolkit -n '__fish_use_subcommand' -s V -l version -d 'Print the version and exit.'
complete -c toolkit -n '__fish_use_subcommand' -s h -l help -d 'Show context-sensitive help.'

# start-ts-cdk-project subcommand: scaffold flags and help.
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -s h -l help -d 'Show context-sensitive help.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l eslint-version -r -d 'Version of eslint, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l eslint-js-version -r -d 'Version of eslint-js, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l typescript-eslint-version -r -d 'Version of typescript-eslint, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l vitest-version -r -d 'Version of vitest, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l vitest-coverage-v8-version -r -d 'Version of vitest-coverage, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l aws-cdk-cli-version -r -d 'Version of the AWS CDK CLI.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l aws-cdk-lib-version -r -d 'Version of the AWS CDK library.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l constructs-version -r -d 'Version of the constructs library.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l esbuild-version -r -d 'Version of esbuild, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l prettier-version -r -d 'Version of prettier, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l tsx-version -r -d 'Version of tsx, a dev dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l typescript-version -r -d 'Version of typescript.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l aws-cdk-assert-version -r -d 'Version of aws-cdk-assert, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l yaml-version -r -d 'Version of yaml, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l gelato-version -r -d 'Version of gelato, a pre-commit hook.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l nodejs-version -r -d 'Only accept major and minor version, i.e. the X.Y format.'
complete -c toolkit -n '__fish_seen_subcommand_from start-ts-cdk-project' -l timeout-seconds -r -d 'Timeout scaffolding after this many seconds.'

# start-python-project subcommand: scaffold flags and help.
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -s h -l help -d 'Show context-sensitive help.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l description -r -d 'Short description of the project'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l gelato-version -r -d 'Version of gelato, a pre-commit hook.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l shell-cmd-on-change-version -r -d 'Version of shell-cmd-on-change, a post-merge hook.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l ruff-version -r -d 'Version of ruff, a linting dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l mypy-version -r -d 'Version of mypy, a linting dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l pytest-version -r -d 'Version of pytest, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l pytest-mock-version -r -d 'Version of pytest-mock, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l pytest-cov-version -r -d 'Version of pytest-cov, a test dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l sphinx-version -r -d 'Version of sphinx, a doc dependency.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l python-version -r -d 'Python 3 interpreter version. Only accept major and minor version, i.e. the 3.Y format.'
complete -c toolkit -n '__fish_seen_subcommand_from start-python-project' -l timeout-seconds -r -d 'Timeout scaffolding after this many seconds.'

# start-go-project subcommand: scaffold flags and help.
complete -c toolkit -n '__fish_seen_subcommand_from start-go-project' -s h -l help -d 'Show context-sensitive help.'
complete -c toolkit -n '__fish_seen_subcommand_from start-go-project' -l go-version -r -d 'Will appear in go.mod and GitHub Actions workflow.'
complete -c toolkit -n '__fish_seen_subcommand_from start-go-project' -l golangci-lint-version -r -d 'Version of golangci-lint, a pre-commit hook.'
complete -c toolkit -n '__fish_seen_subcommand_from start-go-project' -l gelato-version -r -d 'Version of gelato, a pre-commit hook.'
complete -c toolkit -n '__fish_seen_subcommand_from start-go-project' -l timeout-seconds -r -d 'Timeout scaffolding after this many seconds.'

# vim: set ft=fish :
