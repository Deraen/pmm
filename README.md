# PMM - Package Manger Manager!

A tools to describe which packages should be installed on your Ubuntu system.

## Features

- Fast. Run-time is about 1 second if not changes are required.
- "Config" is a bash script so it's easy to install packages conditionally, e.g. by $HOSTNAME.
- Keeps your system tidy.
- Easily manage packages installed on multiple systems.
- ~~tested~~, no promises but:
  - I have used this to bootstrap a new system
  - I have dist-upgraded system where I have used this

## Example

Check [my dotfiles for complete example](https://github.com/Deraen/dotfiles/blob/master/bin/packages.sh).

```bash
#!/bin/bash

# Save this e.g. as ~/bin/packages.sh and run to install / remove packages
# PMM - Package Manager Manager!

. $HOME/.local/modules/pmm/init.sh

# Repos
ppa ubuntu-wine ppa trusty
repo google-chrome "deb http://dl.google.com/linux/chrome/deb/ stable main"

clearRepos

# BASE
install ubuntu-desktop
install ubuntu-minimal
install ubuntu-standard
install lsb-base
install linux-generic
install build-essential
install libnss-myhostname

# And you should add many more packages...
# One way is to add packages and run your package.sh script until no desired packages
# are going to be removed.

# Host specific packages
if [[ "${HOSTNAME}" == "juho-laptop" ]]; then
        # Local package, from url
        install prey 0.6.3-ubuntu2 https://s3.amazonaws.com/prey-releases/bash-client/0.6.3/prey_0.6.3-ubuntu2_all.deb
fi

markauto
autoremove
```
