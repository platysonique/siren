# Publish to GitHub

Repo is committed locally on branch `main`. `gh` was not installed on this machine.

```bash
sudo apt install gh
gh auth login

cd ~/Downloads/waveformstuff
gh repo create bloodsiren --public --description "Dual USB HIFI 8ch judge recording for Waveform on Linux" --source=. --remote=origin --push
```

Or create an empty repo on GitHub, then:

```bash
git remote add origin git@github.com:<user>/bloodsiren.git
git push -u origin main
```

On another laptop:

```bash
git clone git@github.com:<user>/bloodsiren.git
cd bloodsiren
./scripts/install.sh
```
