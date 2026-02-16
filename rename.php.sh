#!/usr/bin/env php
<?php

/**
 * smart-rename
 *
 * Author: Tiago França
 * Website: https://tiagofranca.com
 * Repository: https://github.com/tiagofrancafernandes/smart-rename
 * LinkedIn: https://linkedin.com/in/tiago-php
 * GitHub: https://github.com/tiagofrancafernandes
 *
 * Date: 2026-02-16
 *
 * [CHANGELOG]
 * 2026-02-16:
 *   - Initial release
 *   - Batch rename (glob)
 *   - Regex support
 *   - Interactive mode
 *   - Pretend mode (dry-run)
 *   - Replace and force overwrite
 *   - Single-file rename (mv-like)
 *   - Bash/Zsh autocomplete support
 */

declare(strict_types=1);

/* ---------------- COMPLETION ---------------- */

foreach ($argv as $arg) {
    if ($arg === '--completion-zsh') completionZsh();
    if ($arg === '--completion-bash') completionBash();
}

function completionZsh(): void
{
echo <<<'ZSH'
#compdef srename

_srename() {
  local -a opts
  opts=(
    '--help:Show help'
    '--pretend:Preview only'
    '--interactive:Confirm each rename'
    '--once:Only first match'
    '--regex:Regex pattern'
    '--replace:Allow overwrite'
    '--force:Force overwrite'
  )

  _arguments \
    '1:pattern:_files' \
    '2:from:' \
    '3:to:' \
    '4:path:_files -/' \
    '*::options:->opts'

  case $state in
    opts)
      _describe 'option' opts
      ;;
  esac
}

compdef _srename srename
ZSH;
exit;
}

function completionBash(): void
{
echo <<<'BASH'
_srename_completion()
{
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    opts="--help --pretend --interactive --once --regex --replace --force"

    if [[ ${cur} == --* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    COMPREPLY=( $(compgen -f -- ${cur}) )
}

complete -F _srename_completion srename
BASH;
exit;
}

/* ---------------- HELP ---------------- */

function help(): void
{
    echo <<<TXT
smart-rename

USAGE:
  srename <pattern> <from> <to> [path]
  srename /path/file.txt newname.txt

OPTIONS:
  --regex
  --once
  --pretend
  --interactive
  --replace
  --force
  --help

TXT;
    exit;
}

/* ---------------- ARG PARSER ---------------- */

function parseArgs(array $argv): array
{
    $args = [
        'pattern' => null,
        'path' => '.',
        'from' => null,
        'to' => null,
        'regex' => false,
        'once' => false,
        'pretend' => false,
        'interactive' => false,
        'replace' => false,
        'force' => false,
    ];

    $positional = [];

    foreach ($argv as $arg) {

        if ($arg === '--help') help();
        if ($arg === '--regex') { $args['regex'] = true; continue; }
        if ($arg === '--once') { $args['once'] = true; continue; }
        if ($arg === '--pretend') { $args['pretend'] = true; continue; }
        if ($arg === '--interactive') { $args['interactive'] = true; continue; }
        if ($arg === '--replace') { $args['replace'] = true; continue; }
        if ($arg === '--force') { $args['force'] = true; continue; }

        if (str_starts_with($arg, '--')) continue;

        $positional[] = $arg;
    }

    if (!$args['pattern'] && isset($positional[0])) $args['pattern'] = $positional[0];
    if (!$args['from'] && isset($positional[1])) $args['from'] = $positional[1];
    if (!$args['to'] && isset($positional[2])) $args['to'] = $positional[2];
    if ($args['path'] === '.' && isset($positional[3])) $args['path'] = $positional[3];

    if (!$args['pattern'] || !$args['from'] || !$args['to']) help();

    return $args;
}

/* ---------------- FIND FILES ---------------- */

function findFiles(string $pattern, string $path, bool $regex): array
{
    if (is_file($path)) return [$path];

    $files = [];

    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($path, FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $file) {
        if (!$file->isFile()) continue;

        $name = $file->getFilename();

        $match = $regex
            ? preg_match($pattern, $name)
            : fnmatch($pattern, $name);

        if ($match) $files[] = $file->getPathname();
    }

    return $files;
}

/* ---------------- INTERACTIVE ---------------- */

function ask(string $old, string $new): string
{
    echo "\nRename:\n  FROM: $old\n  TO:   $new\n[y]es [n]o [a]ll [q]uit : ";
    return strtolower(trim(fgets(STDIN) ?: ''));
}

/* ---------------- RENAME ENGINE ---------------- */

function renameFiles(array $files, array $args): void
{
    $processed = 0;
    $renamed = 0;
    $acceptAll = false;

    foreach ($files as $file) {

        $processed++;

        $dir = dirname($file);
        $base = basename($file);
        $new = str_replace($args['from'], $args['to'], $base);

        if ($new === $base) {
            echo "SKIP (no change): $base\n";
            continue;
        }

        $newPath = $dir . DIRECTORY_SEPARATOR . $new;

        if (file_exists($newPath)) {

            if (!$args['replace'] && !$args['force']) {
                echo "SKIP (exists): $new\n";
                continue;
            }

            if ($args['interactive'] && !$args['force'] && !$acceptAll) {
                $answer = ask($base, $new . " (overwrite)");
                if ($answer === 'q') break;
                if ($answer === 'n') continue;
                if ($answer === 'a') $acceptAll = true;
            }

            if (!$args['pretend']) unlink($newPath);
            echo $args['pretend'] ? "[pretend overwrite] $base -> $new\n" : "OVERWRITTEN: $base -> $new\n";

        } else {

            if ($args['interactive'] && !$acceptAll) {
                $answer = ask($base, $new);
                if ($answer === 'q') break;
                if ($answer === 'n') continue;
                if ($answer === 'a') $acceptAll = true;
            }

            if ($args['pretend']) echo "[pretend] $base -> $new\n";
            else { rename($file, $newPath); echo "RENAMED: $base -> $new\n"; }
        }

        $renamed++;
        if ($args['once']) break;
    }

    echo "\nSummary:\n  Matched: " . count($files) . "\n  Processed: $processed\n  Renamed: $renamed\n";
    if ($args['pretend']) echo "  Mode: pretend\n";
}

/* ---------------- ENTRYPOINT ---------------- */

$rawArgs = array_slice($argv, 1);

/* single file rename mode */
if (count($rawArgs) === 2 && is_file($rawArgs[0]) && !str_starts_with($rawArgs[1], '--')) {
    $source = realpath($rawArgs[0]);
    $target = dirname($source) . DIRECTORY_SEPARATOR . $rawArgs[1];

    if (file_exists($target)) {
        fwrite(STDERR, "Error: target already exists\n");
        exit(1);
    }

    rename($source, $target);
    echo "RENAMED: $source -> $target\n";
    exit;
}

/* normal mode */
$args = parseArgs($rawArgs);
$files = findFiles($args['pattern'], $args['path'], $args['regex']);
renameFiles($files, $args);
