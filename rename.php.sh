#!/usr/bin/env php
<?php

/**
 * Author: Tiago França | tiagofranca.com
 * Repo: https://github.com/tiagofrancafernandes/smart-rename
 * https://linkedin.com/in/tiago-php
 * https://github.com/tiagofrancafernandes
 *
 * Date: 2026-02-16
 *
 * [CHANGELOG]:
 * 2026-02-16:
 *   - Initial release: glob/regex batch rename
 *   - Added named arguments support
 *   - Added --pretend dry-run mode
 *   - Added --interactive confirmation (y/n/a/q)
 *   - Added --once (rename only first match)
 *   - Added overwrite modes: --replace and --force
 *   - Added automatic single-file rename mode (mv-like behavior)
 *   - Prevent overwriting unless explicitly requested
 *   - Added summary report
 */

declare(strict_types=1);

/* -------------------------------------------------- HELP -------------------------------------------------- */

function help(): void
{
    echo <<<TXT
Rename files by pattern

USAGE:
  rename.php <pattern> <from> <to> [path]
  rename.php /path/file.txt newname.txt

OPTIONS:
  --pattern=VALUE
  --path=VALUE
  --from=VALUE
  --to=VALUE
  --regex        treat pattern as regex
  --once         rename only first match
  --pretend      dry-run (no changes)
  --interactive  confirm each rename
  --replace      allow overwrite existing files
  --force        overwrite without asking
  --help

Interactive keys:
  y = yes
  n = no
  a = all remaining
  q = quit

TXT;
    exit;
}

/* ------------------------------------------------ ARG PARSER ------------------------------------------------ */

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

        if (str_starts_with($arg, '--')) {
            [$key, $value] = array_pad(explode('=', substr($arg, 2), 2), 2, true);

            match ($key) {
                'pattern' => $args['pattern'] = $value,
                'path' => $args['path'] = $value,
                'from', 'rename-from', 'replace-from' => $args['from'] = $value,
                'to', 'rename-to', 'replace-to' => $args['to'] = $value,
                default => null
            };

            continue;
        }

        $positional[] = $arg;
    }

    if (!$args['pattern'] && isset($positional[0])) $args['pattern'] = $positional[0];
    if (!$args['from'] && isset($positional[1])) $args['from'] = $positional[1];
    if (!$args['to'] && isset($positional[2])) $args['to'] = $positional[2];
    if ($args['path'] === '.' && isset($positional[3])) $args['path'] = $positional[3];

    if (!$args['pattern'] || !$args['from'] || !$args['to']) help();

    return $args;
}

/* ------------------------------------------------ FIND FILES ------------------------------------------------ */

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

/* ------------------------------------------------ INTERACTIVE ------------------------------------------------ */

function ask(string $old, string $new): string
{
    echo "\nRename:\n";
    echo "  FROM: $old\n";
    echo "  TO:   $new\n";
    echo "Choose: [y]es, [n]o, [a]ll remaining, [q]uit : ";

    $line = trim(fgets(STDIN) ?: '');
    return strtolower($line);
}

/* ------------------------------------------------ RENAME ENGINE ------------------------------------------------ */

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
                echo "Target exists!\n";
                $answer = ask($base, $new . " (overwrite)");

                if ($answer === 'q') break;
                if ($answer === 'n') continue;
                if ($answer === 'a') $acceptAll = true;
                if ($answer !== 'y' && $answer !== 'a') continue;
            }

            if (!$args['pretend']) unlink($newPath);

            echo $args['pretend']
                ? "[pretend overwrite] $base -> $new\n"
                : "OVERWRITTEN: $base -> $new";

        } else {

            if ($args['interactive'] && !$acceptAll) {
                $answer = ask($base, $new);

                if ($answer === 'q') break;
                if ($answer === 'n') continue;
                if ($answer === 'a') $acceptAll = true;
                if ($answer !== 'y' && $answer !== 'a') continue;
            }

            if ($args['pretend']) {
                echo "[pretend] $base -> $new\n";
            } else {
                rename($file, $newPath);
                echo "RENAMED: $base -> $new\n";
            }
        }

        $renamed++;

        if ($args['once']) break;
    }

    echo "\nSummary:\n";
    echo "  Matched: " . count($files) . "\n";
    echo "  Processed: $processed\n";
    echo "  Renamed: $renamed\n";
    if ($args['pretend']) echo "  Mode: pretend (no changes made)\n";
}

/* ------------------------------------------------ ENTRYPOINT ------------------------------------------------ */

$rawArgs = array_slice($argv, 1);

/* Direct rename mode (mv-like) */
if (
    count($rawArgs) === 2 &&
    is_file($rawArgs[0]) &&
    !str_starts_with($rawArgs[1], '--')
) {
    $source = realpath($rawArgs[0]);
    $newName = $rawArgs[1];

    $dir = dirname($source);
    $target = $dir . DIRECTORY_SEPARATOR . $newName;

    if (file_exists($target)) {
        fwrite(STDERR, "Error: target already exists: $target\n");
        exit(1);
    }

    rename($source, $target);
    echo "RENAMED: $source -> $target\n";
    exit;
}

/* Normal batch mode */
$args = parseArgs($rawArgs);
$files = findFiles($args['pattern'], $args['path'], $args['regex']);
renameFiles($files, $args);
