# A git prompt for bash

With `git-prompt` you'll _hopefully_ never find yourself again in the following **gruesome** situations:
- Resolving merge conflicts manually because you forgot to `pull` your branch.
- or even worse, `commiting` and `pushing` to the wrong branch :scream:

## Install
Easy to install, just two simple steps:
#### Linux
```bash
git clone -q https://github.com/ezorita/git-prompt
printf "\nsource $(pwd)/git-prompt/git-prompt" >> ~/.bashrc
```
#### MacOS
```bash
git clone -q https://github.com/ezorita/git-prompt
printf "\nsource $(pwd)/git-prompt/git-prompt" >> ~/.bash_profile
```

## Features
It's terribly simple:

![](https://i.imgur.com/Ib5NlHT.jpg)

- ![](https://i.imgur.com/DduOQvp.jpg) Current branch
- ![](https://i.imgur.com/1ZsfjQZ.jpg) Sync status
- ![](https://i.imgur.com/Bk4xkk9.jpg) Commits ahead/behind remote branch
- ![](https://i.imgur.com/cM9C0gq.jpg) Path relative to repository root

### 1. Seamless
Automatically turns on when you `cd` in a git repository.

![](https://i.imgur.com/5pyXgNM.gif)

### 2. Focus on your repo
Working directory in prompt is relative to your repository root.

![](https://i.imgur.com/Ke1SHqg.gif)

### 3. Autofetch
No need to `fetch` anymore. It will automatically `fetch` your current branch every 10 (default) minutes.

![](https://i.imgur.com/y7aP1XK.gif)

### 4. What's new?
Automatically `fetches` when you `cd` to a git repository or change branch.

![](https://i.imgur.com/ozQr0Yb.gif)

### 5. You're out of sync!
Alerts when the last `fetch` has failed.

![](https://i.imgur.com/27yMkO7.gif)

### 6. Easy to turn on and off
Type `GIT_PROMPT=0` or `gitpr` and _voilà_, you're back to your default prompt.

![](https://i.imgur.com/I46F2Lu.gif)

Here is the alias definition, add it to your bash options file:

```bash
alias gitpr='GIT_PROMPT=$((1-{$GIT_PROMPT}))'
```

### 7. Easy to customize
Just set the environment variables.

![](https://i.imgur.com/Rfed9Wh.gif)

## Options
Options can be set directly in the terminal or, if you want to set them permanently, define them anywhere in your `.bashrc` or `.bash_profile` file:

Parameter                     | Description
----------------------------- | --------------------------------------
**GIT_PROMPT**                | Enables/disables `git-prompt` (values `1`/`0`) [default `1`]
**GIT_AUTOFECTH**             | Enables/disables autofecth (values`1`/`0`) [default `1`]
**GIT_AUTOFECTH_INTERVAL**    | Autofetch interval (in seconds) [default `600`]
**Force_Default_Prompt**      | Overwrite the default prompt as well (values `1`/`0`) [default `0`]

### Colors
Colors can be also customized setting the following parameters with [`\[ ... \]`-escaped color sequences](https://stackoverflow.com/a/33206814/2545706):

Parameter                     | Description
----------------------------- | --------------------------------------
**User_color**                | Color of the user field [default _Bold Green_]
**At_color**                  | Color of the `@` symbol [default _Purple_]
**Host_color**                | Color of the host field [default _Bold Blue_]
**Path_color**                | Color of the path field [default _Bold Purple_]
**Branch_color**              | Color of the current branch name [default _Green_]
**Ahead_color**               | Color of the commits ahead indicator [default _Green_]
**Behind_color**              | Color of the commits behind indicator [default _Red_]
**NoSync_color**              | Color of the out-of-sync symbol [default _Red_]
**Fetch_color**               | Color of the `fetch...` message (do not escape with `\[...\]`) [default `\033[0;32m`]
**Git_color**                 | Color of the git prompt indicator `:g~` [default _White_]
**Prompt_color**              | Color of the prompt `$` [default _White_]
**Prompt_error_color**        | Color of the prompt `$` when the last command failed [default _Bold Red_]

## Compatibility
`git v1.9.1`

## Issues and bugs
Feel free to [open a new issue](https://github.com/ezorita/git-prompt/issues/new) if you find a bug or have feature suggestions.

Thanks!
