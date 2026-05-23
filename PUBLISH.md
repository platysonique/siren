# Publish **siren** to GitHub

Repo: **https://github.com/platysonique/siren** (after publish)

```bash
sudo apt install gh    # optional; or use /tmp/gh_2.69.0_linux_amd64/bin/gh
gh auth login          # one-time — browser device code

cd ~/Downloads/waveformstuff
./scripts/publish-github.sh
```

Clone on another laptop:

```bash
git clone git@github.com:platysonique/siren.git
cd siren
./scripts/install.sh
```
