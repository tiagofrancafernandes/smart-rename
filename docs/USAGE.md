# smart-rename Usage Guide

This document contains all usage examples and behavior explanations.

---

## Basic syntax

````

rename.php <pattern> <from> <to> [path]

````

Example:

```sh
rename.php "*.md" draft final ./notes
````

---

## Automatic single file rename (mv-like)

You do NOT need to repeat the path:

```sh
rename.php /home/user/docs/file.txt new.txt
```

Result:

```
/home/user/docs/new.txt
```

Works from any directory.

---

## Preview mode (dry-run)

See what would happen without modifying files:

```sh
rename.php --pretend "*.md" draft final ./notes
```

Output:

```
[pretend] report-draft.md -> report-final.md
```

---

## Interactive mode

Ask confirmation per file:

```sh
rename.php --interactive "*.md" draft final ./notes
```

Prompt:

```
Rename:
  FROM: report-draft.md
  TO:   report-final.md
Choose: [y]es, [n]o, [a]ll remaining, [q]uit :
```

| Key | Action               |
| --- | -------------------- |
| y   | rename file          |
| n   | skip                 |
| a   | rename all remaining |
| q   | abort process        |

---

## Rename only the first match

```sh
rename.php --once "*.log" old new ./logs
```

---

## Overwrite behavior

Default: never overwrite existing files.

### Allow overwrite

```sh
rename.php --replace "*.txt" old new
```

### Ask before overwrite

```sh
rename.php --interactive --replace "*.txt" old new
```

### Force overwrite

```sh
rename.php --force "*.txt" old new
```

---

## Regex mode

Enable regex matching:

```sh
rename.php --regex --pattern="/^img_(.*)\.jpg$/" --from=img_ --to=photo_
```

---

## Named parameters

You can use explicit flags:

```sh
rename.php \
  --pattern="*.md" \
  --from=draft \
  --to=final \
  --path=./notes
```

---

## Practical examples

### Replace spaces with dashes

```sh
rename.php "*.txt" " " "-" ./files
```

### Uppercase extension

```sh
rename.php "*.jpg" .jpg .JPG ./photos
```

### Rename log rotation

```sh
rename.php "app-*.log" app archive ./logs
```

### Clean temporary suffix

```sh
rename.php "*-tmp.*" -tmp ""
```

### Migrate naming pattern

```sh
rename.php "report-*.md" report article ./docs
```

---

## Safety rules

| Situation     | Behavior              |
| ------------- | --------------------- |
| file exists   | skip                  |
| --replace     | overwrite allowed     |
| --interactive | ask                   |
| --force       | overwrite immediately |
| --pretend     | never modify          |

The script will never destroy data unless explicitly instructed.

---

## Tips

Combine preview + interactive for maximum safety:

```sh
rename.php --pretend "*.md" draft final
rename.php --interactive "*.md" draft final
```

## Shell autocomplete

The script can generate completion scripts for your shell.

This enables TAB suggestions for flags and file paths.

---

### ZSH

Install:

```sh
srename --completion-zsh >> ~/.zshrc
source ~/.zshrc
````

Test:

```sh
srename --<TAB>
```

You should see available options like:

```
--pretend
--interactive
--once
--regex
--replace
--force
```

---

### BASH

Install:

```sh
srename --completion-bash >> ~/.bashrc
source ~/.bashrc
```

Test:

```sh
srename --<TAB>
```

---

### What gets autocompleted

* command options (`--pretend`, `--interactive`, etc)
* file paths
* directories

---

### Updating completion

If you update the script, reload your shell:

```sh
source ~/.zshrc
# or
source ~/.bashrc
```

---

### Removing completion

Edit your shell config and remove the block added by the command:

```
~/.zshrc
~/.bashrc
```

```


---

## Philosophy

The goal is to provide:

* predictable behavior
* safe defaults
* portable usage
* minimal dependencies
