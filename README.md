# repo-chores

Repository automation scripts & git hooks for common tedious tasks that keep
reappearing in personal projects.

## Use

The recommended way is to use it as a git subtree:

```
git remote add origin repo-chores https://github.com/dariocc/repo-chores.git
git subtree -P .repo-chores add --squash repo-chores main
```

Then execute the installation script:

```
.repo-chores/install
```

It will perform any initialization required in the `.repo-chores` directory and
configure git hooks under `.git/hooks`.

To revert the installation simply execute the `.repo-chores/uninstall` script.

## List of automation scripts & hooks

__Pre-commit markdown processing hooks__:

- Markdown files are formatted with
  [mdformat](https://github.com/executablebooks/mdformat).
- Markdown code blocks that use the special syntax `!path/to/file` are replaced
  with the contents of the file.

The hook operates staged files and requires those files to not contain unstaged
changes.

For example, consider a recently modified file `foo.md` that has been just
modified with the following contents:

````
# Foo

```!Examples/foo.bar
```
````

When we first attempt to commit the file we see the following:

```
$ git add foo.md


1081 (main) 
$ git commit -m "Change foo"

repo-chores::markdown pre-commit hook

Formatting markdown files...
...DONE!

Embedding code-blocks in markdown files...
...DONE!

Staged markdown files have been formatted and code-blocks have been embedded.
Verify the changes make sense, stage and attempt to commit again.
```

As indicated by the output message we now have some unstaged changes:

```
$ git status

On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   foo.md

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   foo.md
```

We verify that the changes are as expected:

````
$ git diff

diff --git a/foo.md b/foo.md
index fc1476a..d44585d 100644
--- a/foo.md
+++ b/foo.md
@@ -1,7 +1,7 @@
 # Foo
 
 ```!Examples/foo.bar
-Not foo
+This is inside foo.bar!
```
````

And attempt to commit again the changes:

```
$ git add .

$ git commit -m "Change foo"

repo-chores::markdown pre-commit hook

Formatting markdown files... ...DONE!

Embeding code-blocks in markdown files... ...DONE!

Hurray! No changes were required on staged files!

\[main 8fe9208\] Change foo 1 file changed, 2 insertions(+), 2 deletions(-)

```

## Configuration

It is possible to configure certain behaviors by creating a `.repo-chores.json`
file at your repo root with the following schema. All fields are optional unless
otherwise stated.

```json
{
    "markdown" : {
        "wrap_width": 80
    }
}
```
