# lf-tools

A collection of lightweight Go utilities designed to enhance the [lf](https://github.com/gokcehan/lf) terminal file manager on **Windows**.

## Utilities Included

1. **`lf-preview`**: Advanced file preview utility supporting archives (`tar`, `zip`, `rar`, `7z`), PDFs (`pdftotext`), text files with `bat`, and automatic Japanese encoding detection/conversion (`nkf` integration for Shift_JIS/CP932/EUC-JP).
2. **`lf-helper`**: Helper utility to seamlessly execute PowerShell scripts located in `~/AppData/Roaming/lf/` directly from `lf` with the current file (`f`) context and proper terminal I/O handling.
3. **`lf-z`**: Quick directory jumping utility integrated with [zoxide](https://github.com/ajeetdsouza/zoxide) and `lf -remote`.
4. **`lf-zi`**: Interactive fuzzy-find directory selection utility combining `zoxide`, [fzf](https://github.com/junegunn/fzf), and `lf -remote`.

## Configuration Example

An example `lfrc` configuration file and accompanying PowerShell helper scripts are provided in the [`example/`](./example/) directory to help you integrate these utilities into your workflow.

- **`example/lfrc`**: Sample configuration showing key mappings, previewer settings, and integrations for `lf-helper`, `lf-z`, and `lf-zi`.
- **PowerShell Scripts**: Companion `.ps1` scripts designed to be executed via `lf-helper` (e.g., trash handling, file/directory creation, compression, timestamp renaming).

## LICENSE
[MIT License](LICENSE)
