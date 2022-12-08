# blog.dario.nu

My name is Darío Cutillas Carrillo, I'm a software engineer and this is my
personal blog which you can visit in https://blog.dario.nu.

## Building this site

_The following instructions are mostly for the future me_.

If you just cloned the repository, initialize and clone git submodules:

```bash
git submodule init
git submodule update
```

And also install the necessary hooks:

```bash
.repo_chores/install
```

## Convenience scripts

`./configure` Will install netlify `./preview` Preview this site in the browser.
Drafts are enabled. `./deploy` Builds and deploy the site. It will require you
to be able to decrypt `netlify.token`.

## Generating token for deployment

The `netlify.token` contains an encrypted token for deployment.

To generate a new token stored in clipboard use:

```bash
echo "$(wl-paste)" | gpg --encrypt -r foo@bar.com
```

Keeping an encrypted token in the repo sources is for the convenience of being
able to publish the site no matter in which VCS platform I decide to host this
repository.

## Hugo cheatsheet

To create new post

```bash
hugo new --kind chapter posts/article-name/index.md
```

To create content pages:

```bash
hugo new folder/content.md
```

Both asciidocs and markdown contents are supported.

To serve:

```bash
hugo serve
```

To build the website:

```bash
hugo
```

Or use the convenience scripts instead.
