# kidney

Use kidney to apply shell commands to all dart packages in your directory:

```
kidney . --apply --verbose ls
```

## Install

```bash
 dart pub global activate kidney
```

## Examples

| Kidney part    | Command part   | Explenation                      |
| -------------- | -------------- | -------------------------------- |
| `kidney . -av` | `ls`           | Executes ls in all packages      |
| `kidney . -a`  | `flutter test` | Run the tests in all directories |
| `kidney .`     | `ls`           | Start a dry run                  |

## Show help

```bash
kidney
```

## Run tests on all packages

Change into your dev directory containing dart packages.

Execute the following command:

```bash
kidney . -a flutter test
```

## Show the directory contents

To see the folder contents, add the `-v` option and call `ls`:

```bash
kidney . -av ls
```

## Do a dry-run

Remove the `-a` option, to perform a dry run of the desired command:

```bash
kidney . -a ls
```

## All options

| Long        | Short | Explenation                                 |
| ----------- | ----- | ------------------------------------------- |
| `--apply`   | `-a`  | Without that option only a dry-run is done. |
| `--verbose` | `-v`  | Prints CLI output of the commands           |
