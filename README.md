# A git prompt for bash

With `git-prompt` you'll _hopefully_ never find yourself again in the following **gruesome** situations:
- Resolving merge conflicts manually because you forgot to `pull` your branch.
- or even worse, `commiting` and `pushing` to the wrong branch :scream:

## Install
Easy to install, just three simple steps:
#### Linux
```bash
cd ~
git clone -q https://github.com/ezorita/git-prompt
printf "\nsource $(pwd)/git-prompt/git-prompt" >> .bashrc
```
#### MacOS
```bash
cd ~
git clone -q https://github.com/ezorita/git-prompt
printf "\nsource $(pwd)/git-prompt/git-prompt" >> .bash_profile
```

## Features
It's terribly simple:

![](https://i.imgur.com/Ib5NlHT.jpg)

- ![](https://i.imgur.com/DduOQvp.jpg) Current branch
- ![](https://i.imgur.com/1ZsfjQZ.jpg) Sync status
- ![](https://i.imgur.com/Bk4xkk9.jpg) Commits ahead/behind remote branch
- ![](https://i.imgur.com/cM9C0gq.jpg) Path relative to repository root

### Seamless
Automatically turns on when you `cd` in a git repository.

![](https://i.imgur.com/5pyXgNM.gif)

### Focus on your repo
Shown path is relative to your repository root.

![](https://i.imgur.com/Ke1SHqg.gif)

### Autofetch
No need to `fetch` anymore. It will automatically `fetch` your current branch every 10 (default) minutes.

![](https://i.imgur.com/y7aP1XK.gif)

### What's new?
Automatically `fetches` when you `cd` to a git repository or change branch.

![](https://i.imgur.com/ozQr0Yb.gif)

### You're out of sync!
Alerts when the last `fetch` has failed.

![](https://i.imgur.com/27yMkO7.gif)

### Easy to turn on and off
Just type `GIT_PROMPT=0` or `gitpr` and _voilà_, you're back to your default prompt.

![](https://i.imgur.com/I46F2Lu.gif)

Here is the alias definition, add it to your bash options file:

```bash
alias gitpr='GIT_PROMPT=$((1-{$GIT_PROMPT}))'
```

### Easy to customize
Just set the environment variables.

![](https://i.imgur.com/Rfed9Wh.gif)

## Issues and bugs
Feel free to [open a new issue](https://github.com/ezorita/git-prompt/issues/new) if you find a bug or have feature suggestions.

Thanks!
