# pkgbuild-action

Build AUR package and generate `.SRCINFO`.

## Interface

Inputs:

* `path`: Path to `PKGBUILD` directory.

Outputs

* `pkgfile`: Filename of built package.

## Example

```yaml
- name: Make packages
  uses: pmphan/pkgbuild-action@master
  id: makepkg
  with:
    path: pkgname
- name: Upload package
  uses: actions/upload-artifact@v4
  with:
    path: ${{ steps.makepkg.outputs.pkgfile }}
```
