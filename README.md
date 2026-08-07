# mxllmann/homebrew-tap

Homebrew formulae.

```sh
brew tap mxllmann/tap
```

## Formulae

| Formula | Description |
|---|---|
| [`batcycle`](https://github.com/mxllmann/batcycle) | Battery cycle history for macOS — daily usage and the exact moment each charge cycle completed |

```sh
brew install mxllmann/tap/batcycle
```

## Releasing

After tagging a release in the tool's own repository:

```sh
./bump.sh batcycle 0.1.0
brew install --build-from-source ./Formula/batcycle.rb   # verify
git commit -am "batcycle 0.1.0" && git push
```
