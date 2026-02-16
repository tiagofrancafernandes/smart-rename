# smart-rename

A tiny yet powerful CLI file renaming tool.

Safer and more interactive than traditional `rename` and more flexible than `mv`.

It supports batch renaming, preview mode, confirmation prompts, overwrite control and automatic single-file rename detection.

Works on any system with PHP CLI installed.

---

## Install (quick)

### Using wget
```sh
wget https://raw.githubusercontent.com/tiagofrancafernandes/[repo-name]/refs/heads/master/rename.php.sh -O rename.php.sh \
&& chmod +x rename.php.sh \
&& ./rename.php.sh --help
````

### Using curl

```sh
curl -fsSL https://raw.githubusercontent.com/tiagofrancafernandes/[repo-name]/refs/heads/master/rename.php.sh -o rename.php.sh \
&& chmod +x rename.php.sh \
&& ./rename.php.sh --help
```

---

## Global install

```sh
sudo curl -fsSL https://raw.githubusercontent.com/tiagofrancafernandes/[repo-name]/refs/heads/master/rename.php.sh -o /usr/bin/srename \
&& sudo chmod +x /usr/bin/srename
```

Then:

```sh
srename --help
```

---

## Documentation

Full usage examples and explanations:

👉 **[docs/USAGE.md](docs/USAGE.md)**

---

## Features

* Batch rename with glob
* Regex mode
* Interactive confirmation
* Dry-run preview
* Safe overwrite handling
* Automatic single-file rename mode
* Recursive directories
* Named arguments support

---

## License

#### [Unlicensed](./LICENSE)
