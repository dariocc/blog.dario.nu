---
title: good-old-bash-for-ci-scripts
date: 2022-12-06
draft: true
---

# Good Ol' Bash for CI

Bash, loved by some, hated by others...As for me I'd describe my relationship
with Bash as _it's complicated_: I do appreciate its conciseness, string
manipulation capabilities and ability to directly invoke commands, but I also
suffer its quirks and struggle sometimes to remember all of its syntax,
specially after a period of programming in other languages.

But like it or not Bash is _a_ if not the _king_ of CI logic... It's ubiquitous
and almost any worthy CI system allows embedding bash logic into their CI jobs:
GitLab CI, GitHub Actions, Bitbucket Pipelines, Jenkins, ... you name it Even if
in the cases you can choose your shell Bash is often the default.

So rather than _fighting it_, let's fight with it. I've summarized some
practical advise with regards to the use and abuse of Bash logic for CI.

## It only takes a bit of frustration to get started

I've been an active Linux since 2012 but my active shell scrip learning didn't
start until much later. In 2017 after a job change I found myself using shell
scripting much more often than I had needed until then. I was frustrated by how
inefficient I was in modifying shell scripts, many of them would only show their
behavior in CI.

All it took for me was one bored summer day in the
[Lomma Beach](https://www.tripadvisor.com/Tourism-g1898350-Lomma_Skane_County-Vacations.html),
a Kindle and a
[Free ebook](https://www.amazon.com/Shell-Scripting-Automate-Command-Programming-ebook/dp/B015FZAXU6)
to get started. It was not about Bash but mostly POSIX shell scripting, which
turned out to be a good thing, since it reduced the scope of what I needed to
learn first.

That simple reading really made a huge difference. For example, I would
understand that the opening bracket `[` was a _command_ (equivalent to `test`)
and not punctuation symbol. This opened the door to understand the apparently
weirdness of `if [ ... ]` expressions.

So if you feel frustrated for being inefficient at writing shell scripts, I can
recommend a similar approach to what I did: grab a book, focus on POSIX shell
and overcome your procrastination :).

With the right foundation in place, you'll be able to learn Bash _on the go_ as
you want to _do more with less_ and you browse Stack Overflow answers.

## Double-quote everywhere until you know why you are not double-quoting

The rule of thumb to never mess up with shell expansion is to always double
quote when you see the dollar sign:

```bash
file=my\ word\ document
cat $file # Wrong! Use "$file"
```

This is because of how [word-splitting] works:

Word splitting refers to how the shell interprets spaces. In the above example,
because `file` contains spaces, when the value of `$file` is expanded, it is
passed as 3 arguments to the `cat` command, which is likely not what you want.
Unwanted word-splitting due to missing quotes is also a door for \[OS command
injection\]\[os-command-injection\] which might be dangerous depending on where
your scripts are executing.

\[os-command-injection\]\[https://owasp.org/www-community/attacks/Command_Injection\]

The previous example double quoted a variable, but the principle is applicable
to anything with a `$` sign. Example:

```bash
foo="$(cat "$file")"
```

And while that looks weird

So the easy thing to remember is: __always double quote when you see a $ sign__.

Once you learn that, you can learn _when to not use it_:

```bash
colors="red yelloy green"
for color in $colors
do
    echo "$color"
done
```

If we would've used `$colors`, the for loop would have iterated only over one
parameter.

You might be wondering if it would be possible to have a collection of strings
that may contain spaces such as _antique white_. It is possible, for example by
using arrays, which is a _Bash_ feature and not POSIX compatible:

```bash
colors=(red yellow green "antique white")  # Parenthesis denote an array
for color in "${colors[@]}"
do 
    echo "$color"
done
```

But now we used `"`, what? I'm with you, it feels weird, but that is the way it
works: `"${colors[@]}"` is the way to expand `colors` elements double quoting
each element, i.e. the above example is equivalent to the following:

```bash
for color in "red" "yellow" "green" "antique white"
do
    echo "$color"
done
```

My advise would be to stop thinking of _text within quotes_ as _strings_ with
your C#, Python, _replace with your language_ eyes and train them to the Bash
idioms.

## Use locally scoped variables in functions

Consider the following example:

```bash
say_hello() {
    who="$1"

    if [ -n "$who" ]; then
        echo "Hello $who!"
    else
       return 1
    fi
}

say_goodbye() {
    # Ops! We forgot to assign who

    if [ -n "$who" ]; then
        echo "Hello $who!"
    else
        return 1
    fi
}

say_hello "Darío"
say_hello "Mark"
say_goodbye "Darío"
```

The above will say hello to both me and _Mark_ but will wrongly say goodbye to
_Mark_ instead of me. Of course, it was a programming mistake, but one that it
is frequent enough so as to want to avoid it. In many cases, this sort of issue
can be confusing because it makes you think that a `say_goodbye` is actually
working.

We can use `local` to restrict the scope of a variable:

```bash
say_hello() {
    local who
    ...
}
```

Now the call to `say_goodbye` would return a non zero exit code and, because it
is the last line of the script, the script will fail.

Using `local` brings me peace of mind. But again, Bash surprises with some
_uncommon_ things of doing things: `local` is a _Bash built-in_ (i.e., a command
that is available if you use Bash) and not a syntax keyword, which means it will
return 0 or 1. This has implications.

Consider the following code:

```bash
set -e
foo() {
    local bar="$(exit 1)"
}

foo
echo "I made it to the end!"
```

One would expect the call to `foo` to fail, because `$(exit 1)` is returning a
non zero exit code. However this is not what happens and the text
`I made it to the end!` is printed.

Again, `local` is a built-in command and the exit code of this command is always
`0`, regardless of what happened on the right side.

Therefore, it is sometimes recommended to separate _local variable declaration_
from _variable assignment_.

### Learn to love parameter expansion

I found it awkward and difficult to remember at first but I admire its
conciseness and usefulness. [Parameter expansion][parameter-expansion] is like
string interpolation on steroids.

This are some of the expressions you should get to know:

|                     | parameter _set_ and _not null_ | parameter _set_ but _null_ | parameter _unset_ |
| ------------------- | ------------------------------ | -------------------------- | ----------------- |
| `{parameter:-word}` | parameter                      | word                       | word              |
| `{parameter-word}`  | parameter                      | null                       | word              |
| `{parameter:+word}` | word                           | null                       | null              |
| `{parameter+word}`  | word                           | word                       | null              |
| `{parameter:?word}` | parameter                      | error, exit                | error, exit       |
| `{parameter?word}`  | parameter                      | null                       | error, exit       |

If you think that is hard to remember, you are not alone. I use the following
mnemonics:

- I associate `-` to what happens when `parameter` is _missing_.
- `+` tells me about what to do if `parameter` is _present_.
- `?` is asking _has it been set_?
- If no other symbol is used, `null` is considered just like any value.
- With `:` we make `null` be handled as if it was unset.

The forms I use the most are `:-`, `:+` and `:?`, since normally `null` almost
always represents _unset_ to me.

__Example 1: Validating required variables__:

```bash
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:?Missing GITHUB_WORKSPACE variable, are you running from CI?}"
```

__Example 2: Providing reasonable defaults:__

```bash
OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/stdout}"
```

__Example 3: Passing optional arguments__

Often I feel the need to specify flags in commands depending on wether a given
variable has been assigned.

For example, let's say you have an scrip that takes an input `VERSION` as an
environment variable and that should determine whether you pass a
`--version "$VERSION"` argument to the `dotnet` command:

```bash
   dotnet publish ${VERSION:+--version "$VERSION"} --no-build .
```

If `VERSION` has ben set, the `{ ... }` expression will be substituted with
`--version "$VERSION"`. If it is `null` or `unset` nothing will be substituted.
Notice that __${...}__ is not within quoted. Because of how
[word splitting](word-splitting) works in Bash it would just be as if you
would've substituted the whole thing by a space.

Notice that within the expansion expression I did double-quoted `"$VERSION"`.
This prevents any further word-splitting to occur,

### Other shell expansion expressions

There are more shell expansion features, for example:

- `{#parameter}` for replacing with the length of _parameter_.
- `{parameter#pattern}`, `{parameter##pattern}`, `{parameter%pattern}` or
  `{parameter%%pattern}` to remove parts of the string. For example, the `%` or
  `%%` are very useful to remove extensions from filenames.
- `{parameter/pattern/string}` for replacing patterns with _string_.

Even if I recognize that memorizing these patterns requires training and will,
they are really useful for manipulating strings, something that is very common
in CI logic.

## There is no shame in not being compliant with POSIX

Bash is a superset of POSIX shell and as such you might be tempted to write
_portable code_. I rarely find this useful for usual desktop unix based
operative systems. And doing some common things such as _extracting the basename
of a file_ or _the directory_ get much more complicated without certain Bash
built-ins.

Bash is the norm and not the exception and if it happens to not be the default
shell of your OS, I expect you to install it :). I don't care if you prefer
`Zsh` or other.

This is even truer if we are talking about CI (which we are), where you normally
have control over what tools are available in the hosts of the runners of your
CI jobs.

## Show your manners when calling things

When command invocations get a bit complex I tend to prefer the following form:

```bash
command \
    --arg-1 arg-1-value \
    --arg-2 arg-2-value \
    --arg-4 arg-4-value \
    --arg-5 arg-5-value \
    --arg-6 arg-6-value \
    --arg-7 arg-7-value \
    --arg-8 arg-8-value
```

Rather than:

```bash
command --arg-1 arg-1-value --arg-2 arg-2-value --arg-4 arg-4-value --arg-5 arg-5-value --arg-6 arg-6-value --arg-7 arg-7-value --arg-8 arg-8-value
```

In this particular example, the benefit might not be that clear, but if those
`arg-x-value` contain subshell invocations, variables or quotes, it really makes
a difference. Plus the former is easier to review when you are diffing.

## If possible, make it possible for your scripts to execute from any folder in the repo

It is really annoying to have to _cd_ into a directory just to be able to
execute a specific script. Normally it is possible to make your scripts work
independently on where they are invoked,.

Depending on which particular path you are dealing with I'd suggest one of the
following approaches:

__Path is a sibling or child to the directory of the script__

Define a `SCRIPT_DIR` variable containing the path of the directory of the
script:

```bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")" and define paths
```

Then make path relative to this directory:

```bash
FOO_FILE="$SCRIPT_DIR/foo"
```

__Paths is not a sibling or child of the directory of the script__

Define a `REPO_PATH` variable containing the path of the root directory. If you
can afford invoking git (for many CI cases, you can):

```bash
REPO_PATH="$(git rev-parse --show-toplevel)"
```

If you can't, you may instead define paths relative to `SCRIPT_DIR`.

## Split your script functionality in well named functions

You do it when you write C#, Java or Python, so why don't you do it also in your
scripts?

Splitting you commands in functions increases drastically readability. Suddenly
you can understand what the script is supposed to be doing at high level without
knowing the details.

Compare:

```bash
git clone --depth 1 ...
gawk -i inplace -F. '/[0-9]+\./{$NF++;print}' OFS=. .version
git commit -a -m "Bump version" && git push
```

Against:

```bash
clone_repo_shallowly() {
    git clone --depth 1 ...
}

bump_patch_version() {
    gawk -i inplace -F. '/[0-9]+\./{$NF++;print}' OFS=. .version
}

commit_and_push() {
    git commit -a -m "Bump version" && git push
}

clone_repo_shallowly 
bump_major_version
commit_and_push
```

## It's okay to consume external inputs directly in functions

When I started to structure my scripts logic into separated functions I thought
it would be bad practice to make those function depending on _global variables_
defined at script level.

```bash
clone_repo_shallowly() {
    local repo_url="$1"
    git clone --depth 1 "$repo_url"
}
```

However, experience has taught me that this doesn't really bring much value.

Instead I've started to see my scripts as _modules_ and functions as _member
variables_ of that module, and that it is okay for a function to be aware of the
state of the module, similar to how member functions in Object Oriented
languages are allowed to access member variables.

What I do avoid however is to make functions aware of variables that aren't
assigned within the script. To me, those represent global state and should
therefore not be known by the functions.

So for example, I avoid the following:

```bash
delete_all_files_under_foo() {
    rm -rf "$GITHUB_WORKSPACE/foo"
}

delete_all_files_under_foo
```

By my own convention I would consider functions should not know about
`$GITHUB_WORKSPACE`. Instead I shall do:

```bash
delete_all_files_under_foo() {
    rm -rf "$GITHUB_WORKSPACE/foo"
}

# Re-assigning the variable to declare our intent of making it part of the script
GITHUB_WORKSPACE="${GITHUB_WORKSPACE}:?}"  # Re-assingTake the chance to validate that it is set...
```

Following this practice it is relatively simple to find out which inputs a
script requires, since

- Input reading and validation is kept in the same section of the script.

## An example

```bash
#!/bin/bash

SCRIPT_DIR="$(dirname "$(basename "${BASH_SOURCE[0]}")")"

TOOL_GIT="${TOOL_GIT:-git}"


# Utility functions

die() {
    printf "ERROR: %s\n" "$1"
    exit 1
}

ssh_to_https_url() {
    local url="$1"
}

# Script logic 

clone_repo_shallowly() {
    "$TOOL_GIT" clone --depth 1 "$(ssh_to_https_url "$REPO_URL")"
}

do_something_interesting() {
    # ...
    echo "Result"
}

# Input Retrieval and Validation

# Basic null/empty validation is delegated to parameter expansion
REPO_URL="${REPO_URL:?Missing required REPO env}"

# Do any additional input validation that is required
if [[ $REPO_URL =~ ^git:// ]];
then
    die "REPO_URL needs to match ^git://"
fi

# Script loic body is delegated
clone_repo_shallowly || die "Failed to clone repo"
do_something_interesting || die "Failed to do something interesting"
```

In Python I used to encapsulate the main body of the script also in a `main()`
function. I used to do that too in my first Bash scripts. However I do no longer
see a reason for that, it just increases indent and I don't need each action

## It is possible to write CLIs in Bash, but you might want not to

While it is possible

```bash
POSITIONAL=()               # An array to capture positional arguments
while [[ $# -gt 0 ]]; do    # We still have arguments to process arguments ($#) is greater than 0
    argname="$1"            # Pick the first argument in the argument stack
    case "$argname" in
        --version)          # An argument for which we want a value
            VERSION="$2"    # Map the argument value to an internal variable name
            shift; shift    # Pop two arguments from the argument stack one containing the argument name and the other containing the value
            ;;
        --dev)              # A flag or "boolean" argument
            DEV_FLAG=1      # Arguments that are flags do not need a value
            shift           # Pop one argument from the argument stack
            ;;
        --help)             # An argument that should generate an immediate action
            help
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL\[@\]}" # restore positional arguments
```

However, a CLI might provide for a better user experience if a given script.

It is possible to process arguments. I've done it, and every time I've hated it.

I've learned to accept _environment variables_ as the way to pass information to
CI scripts.

The only _but_ I have about this approach is that I can technically end-up with
_accidentally set variables_. To avoid that, always set ALL variables from your
script _wrapper_.

In my opinion, CI logic that takes more

## It's okay

I believe every developer could benefit of learning Bash and be able to
understand most of it's idioms.

In today's world of fast-paced development it is more often than not to see
programmers that avoid Bash at all costs, which is a pity because Bash has
something to offer to them: it is king in sysadmins's land and I think it has
it's space as _plumbing code_ for CI/CD scripting. It allows for code brevity,
rapid prototyping and expressivity. But

I know what they say, that code is _read far more often than it's written_, and
I agree: if your CI logic get complex, it might be time to adopt a different
language.

If you have the luxury of being able to _impose_ a language for CI, there might
be other options that are good: `Python` and `Go` come to my mind. I happen to
work in a team with a mixed skill-set and not everyone likes Python or is
competent in `Go`. We'd need an authoritative decision to pick _one to rule them
all_ if that was to happen.

I get the feeling that not everyone is comfortable with Bash either, at least
based on the scripts I read. But for some strange reason, it seems acceptable to
write _bash for CI_ even when not everyone in a team might feel comfortable with
it.

But when it comes to wiring-up commands, manipulating strings or quickly setting
up CI/CD configuration, Bash kick-asses. Personally, I find I'm a more complete
developer knowing Bash that not knowing it, and it feels great to have overcame
my initial reluctancy towards this good old language.

## Use shellcheck

Also talk about actionlist.

## Closing

I'd like to close with a quote from one of my favorite programming books
[the Pragmatic Programmer][the-pragmatic-programmer]:

> _Care about your craft: Why spend your life developing software unless you
> care about doing it well_.

Which I will rewrite for the occasion:

> _Care about your Bash: Why spend your days writing CI logic in Bash unless you
> care about doing it well_.

Thank you for making it to the end and see you in the next article!

<!-- References -->

## TODO

- fail_trap example
- functions that depend on external inputs

[parameter-expansion]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[the-pragmatic-programmer]: https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition
[word-splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html
