If you just cloned the repository, initialize and clone git submodules:

    git submodule init
    git submodule update

## Convenience scripts

./configure     Will install netlify
./deploy        Builds and ploy the site

## Generating auth token

The `netlify.token` contains an encrypted token for deployment.

To generate a new token stored in clipboard use:

    echo "$(wl-paste)" | gpg --encrypt -r foo@bar.com

## Hugo commands

To create new chapters:

    hugo new --kind chapter basics/_index.md

To create content pages:

    hugo new basics/first-content.md
    hugo new basics/second-content/_index.md

To serve:

    hugo serve

To build the website:

    hugo


