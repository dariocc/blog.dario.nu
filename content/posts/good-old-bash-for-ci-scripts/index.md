---
title: Good Old Bash for CI scripts
date: 2022-12-08
draft: false
tags: [linux, bash, devops, CI]
languages: [en]
---

Bash, loved by some, hated by others...As for me I'd say _it's complicated_: I
have use it enough to learn to appreciate its conciseness, string manipulation
capabilities and ability to directly invoke commands, but I've also struggled
its quirks and way of doing things different than other from other languages I
use to write scripts.

But like it or not Bash is a king if not the _king_ when it comes to CI logic...
It's ubiquitous and almost any worthy CI system will allow embedding bash logic
into their job definitions, often making it the default choice for jobs running
in Linux.

If you happen to touch Bash in your daily ops but still feel uncomfortable with
it, keep reading: I've summarized some practical advice that hopefully will help
you gain more confidence with it.

## It only takes a bit of frustration to get started

I've been an active Linux since 2012 but my active shell scrip learning didn't
start until much later. In 2018 after a job change I found myself using shell
scripting much more often than I had needed until then. I was frustrated by how
inefficient I was in modifying shell scripts, many of them would only show their
behavior in CI.

Then one bored summer of the same year, vacationing in
[Lomma Beach](https://www.tripadvisor.com/Tourism-g1898350-Lomma_Skane_County-Vacations.html),
I picked up my Kindle and downloaded the free
ebook[Shell Scripting, How to Automate Command Line Tasks Using Bash Scripting and Shell Programming](https://www.amazon.com/Shell-Scripting-Automate-Command-Programming-ebook/dp/B015FZAXU6)

Short book, free, straight to the point. It was eye opener and I would quickly
learn things such as the opening bracket `[` was a _command_ (equivalent to
`test`) and not punctuation symbol. No longer I would struggle to interpret
`if [ ... ]` constructions.

This isn't really an advice, is it? Well I guess my point is: are you frustrated
enough? Do you feel unproductive? Then it's about time to change that.

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
Unwanted word-splitting due to missing quotes is also a door for
[OS command injection][os-command-injection] which might be dangerous depending
on where your scripts are executing.

Here there is a more confusing example:

```bash
foo="$(cat "$file")"
```

It is confusing because it seems we have a _string_, then a variable and then
another string. But this is reading bash code as if it was another programming
language. It is not.

Quotation, and in particular double quotes denote that _literals characters
shall be preserved_ except when certain symbols such as `$` appear. `$(...)` and
`$file` are _expansions_ and expansions have a well-defined
[order of precedence](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06).

The way I imagine this is that the _inner quotes_ have less precedence than the
`$(..)` and therefore `$file` needs to be quoted if I want spaces to be
preserved when passed to `cat`.

Once you've taught yourself to double-quote everything you may start relaxing
the policy when you want word splitting to happen:

```bash
colors="red yelloy green"
for color in $colors
do
    echo "$color"
done
```

If we would've written instead `"$colors"`, the for loop would have iterated
only over one parameter.

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

This _magic_ is similar to the expansion `$@`, that will expand arguments passed
ot the script as if they were passed double quoted, as opposed to `$*`.

My advise would be to stop thinking of _text within quotes_ as _strings_ with
your C#, Python, and start thinking in terms of _expansions_ and how they work
in Bash.

Running [shellcheck](https://www.shellcheck.net/) over your scripts is a great
way to improve your shell knowledge without having to remember all the rules,
since it will remind you to double quote when expanding variables and commands.

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
from _variable assignment_. I tend to apply this advise only when dealing with
expressions that may fail, as I dislike the extra verbosity that it is
introduced by doing it indiscriminately.

### Learn to love parameter expansion

I found it awkward and difficult to remember at first but I admire its
conciseness and usefulness. [Parameter expansion][parameter-expansion] is like
string interpolation on steroids.

Here there are some examples:

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

There are more shell expansion features that you may want to learn, for example:

- `{#parameter}` for replacing with the length of _parameter_.
- `{parameter#pattern}`, `{parameter##pattern}`, `{parameter%pattern}` or
  `{parameter%%pattern}` to remove parts of the string. For example, the `%` or
  `%%` are very useful to remove extensions from filenames.
- `{parameter/pattern/string}` for replacing patterns with _string_.

Even if I recognize that memorizing these patterns requires training and will,
they are really useful for manipulating strings, something that is very common.

My advice is to find some mnemonics that work for you. For example the
`{parameter%pattern}` is easy to remember by imagining of holding scissors with
the right hand and a stripe on your left hand and the pattern being cut out the
stripe and falling off the right side.

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
`arg-x-value` contain command expansions, variables or several pair of quotes,
it really makes a difference. Plus the former is easier to review when you are
diffing.

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
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
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

If you can't, you may instead define paths relative to `SCRIPT_DIR`. With the
first approach, your script will break if the file or path you are referencing
changes. With the second approach you are also sensitive to changes to the
directory of the script itself.

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

Now even a person that doesn't know `gawk` knows what is going on and will be
less scared to go and fix things when something breaks.

Save yourself from being _that guy_ that is called when that job fails.

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
#!/bin/bash

delete_all_files_under_foo() {
    rm -rf "$GITHUB_WORKSPACE/foo"
}

delete_all_files_under_foo

# End of the script
```

My self-imposed convention tells me that globally defined variables accessed in
functions shall be at least being defined once within the _body_ of the script.
By _body_ I mean here the code outside functions (if there is a name to call
that, please let me know).

So the following would be ok:

```bash
#!/bin/bash
delete_all_files_under_foo() {
    rm -rf "$GITHUB_WORKSPACE/foo"
}

# Re-assigning the variable to declare our intent of making it part of the script
GITHUB_WORKSPACE="${GITHUB_WORKSPACE}:?}"  # Re-assingTake the chance to validate that it is set...
```

If it makes sense, I may even take the change to use script-specific naming,
instead of depending on specific CI naming. So for example `REPO_ROOT`. This
makes me feel better if I run the script locally, since `GITHUB_WORKSPACE`
doesn't really make sense in that context.

This might not always be practical. Sometimes your script is actually bound to
your underlying CI system and it is okay to name things in the same terms. I
think the key is to think whether you can imagine running that script locally,
even if it is to _try it out_. If you can, then it is good to add the additional
semantic abstraction.

Independently of the name you choose, one great advantage of following the rule
of _no global variable shall be accessed from a function unless it has been
assigned in the script body_ is that suddenly knowing what inputs your script
takes is much easier, because every requirement is concentrated in the same
section of the script.

## Encapsulate failure exit routines

All my scripts have a _die_ function:

```bash
die() {
    printf "ERROR: %s\n" "$1"
    exit 1
}
```

Which then I use as:

```bash
do_something || die "I couldn't do what you asked"
do_something_else || die "Sorry but this operation isn't available"
```

This is to me much more expressive than echoing and exiting:

```bash
if do_something; then echo "Error" && exit 1; fi
```

## Watch out for operator precedence

Note also that operator precedence works a bit different in Bash than in other
languages. Let's recall the example in the previous section:

```bash
if do_something; then echo "Error" && exit 1; fi
```

You might be thinking of rewriting it like this

```bash
do_something || echo "Error" && exit 1
```

You'd be surprised that this exits in any case: `||` and `&&` have the same
precedence here, and left-to-right precedence rule takes place:

- If `do_something` returns `0` exit code, `echo "Error"` is short-circuited,
  and then the right operand of the `&&` operator is evaluated.

This is unlike other languages, where _logical AND_ have greater precedence than
_logical OR_.

To complicate things even further, operator precedence is context-dependent. For
example, inside `[[...]]` or when passed to the `[` command, `&&` will indeed
have greater precedence and behave more like you would expect.

The solution is to either use parenthesis to fix precedence or to stay away from
these one-liners. I normally choose the latter because I don't trust my ability
to remember these rules every time.

## Structuring your scripts

It takes time to develop a _script style_ that you are comfortable with. Through
multiple iterations I've ended up with the following:

```bash
#!/bin/bash

# Constants and external tools seams
SCRIPT_DIR="$(dirname "$(basename "${BASH_SOURCE[0]}")")"
# I like to add seams to tools I depend on in the script
TOOL_GIT="${TOOL_GIT:-git}"

# Basic null/empty input validation is delegated to parameter expansion
REPO_URL="${REPO_URL:?Missing required REPO env}"

die() {
    printf "ERROR: %s\n" "$1" 1>&2 # Error messages should go to stdout
    exit 1
}

# ... And warning(), info(), debug() if I'm going to be having that sort of output

# Script logic

clone_repo_shallowly() {
    "$TOOL_GIT" clone --depth 1 "$REPO_URL"
}

do_something_interesting() {
    # ...
    echo "Result"
}

# More complex input validation appears in the 'body' of the script
if [[ $REPO_URL =~ ^git:// ]];
then
    die "REPO_URL needs to match ^git://"
fi

# Finally, the program flow
clone_repo_shallowly || die "Failed to clone repo"
do_something_interesting || die "Failed to do something interesting"
```

This way I can:

- Look at the top of the script to know what environment variables it depends
  son
- Look at the bottom of the script to get an overview of the script logic,
  without being concerned about the specific implementation details.

This style is simple enough to remember and it puts you in a better place for
making it unit-testable, should that be something you want to consider. Script
testability is a wider topic and I hope to cover it in future posts.

## It's okay to use environment variables to accept input

During a long time I was convinced that _programs should be explicit about the
inputs they take_ and _not depend on environment variables_ as input.

I would therefore put command line interface on top of my scripts. For example.
this is one of my favorite ways of building a simple CLI without depending on
commands such as `getops`:

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

While a CLI might provide for a better user experience, it is rarely useful for
CI purposes and it can even be detrimental. To begin with, it requires a ton of
code. Code which is often difficult to understand by those less familiar with
Bash But also because CI platforms make it often easy to assign values to
environment variables, so if you use them as inputs, things get more structured.

For example, in GitHub Actions a `foo-a-bar` action may look like this:

```yaml
# foo-a-bar/action.yml
name: Foo a bar
inputs:
    foo:
        description: A foo
        required: true
    bar:
        description: A bar
        required: true
runs:
  using: composite
  steps:
    - run: |
        .github/actions/foo-a-bar-action/foo-a-bar
      shell: bash
      env:
        FOO: ${{ inputs.foo }}
        BAR: ${{ inputs.bar }}
```

Having a CLI in the `foo-a-bar` script would make the inputs to appear within
the _run_ block:

```yaml
    - run: |
        .github/actions/foo-a-bar-action/foo-a-bar --foo ${{ inputs.foo }} --bar ${{ inputs.bar }}
```

Aesthetically the first example offers a bit more of structure. Environment
variables are also easier to work with when scripts represent the entry point of
Docker images.

So my current thinking is that the additional effort required to design a CLI
only makes sense when you expect your scripts to be regularly invoked by humans
and not primarily by CI jobs, for those situations, you might actually want to
consider other programming languages that offer better argument parsing
experiences.

If you want to stick to Bash, [autogenerating](https://autobash.dev) CLIs might
be an interesting option instead of manually writing it.

## Your scripts files don't need file extensions

I see this a lot, likely due to the influence Windows has had in our minds, but
in Unix land _executables are expected to not have any extension_. That is the
way to visually distinguish if a file is executable or not without checking out
its permissions. And you know what they say: _when in Rome, do as the roman do_:
`build-and-run` and __not__ `build-and-run.bash`.

IDEs and code editors are smart enough to figure out the language anyway.

The only case where I think it is justified to use an extension is when you
create shell code that is intended to be _sourced_ and not to be executed.

## Closing

Bash may be for you or not, but it definitely has something to offer.

If you happen to be in the position to make authoritative decisions for your
team, choosing a different language to implement CI logic might be possible, and
even a _good thing_. Still you'll hit many situations where Bash knowledge is
useful.

I'd like to close with a quote from one of my favorite programming books
[the Pragmatic Programmer][the-pragmatic-programmer]:

> _Care about your craft: Why spend your life developing software unless you
> care about doing it well_.

Which I will rewrite for the occasion:

> _Care about your Bash: Why spend your days writing CI logic in Bash unless you
> care about doing it well_.

Thank you for making it to the end and see you in the next article!

<!-- References -->

[os-command-injection]: https://owasp.org/www-community/attacks/Command_Injection
[parameter-expansion]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[the-pragmatic-programmer]: https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition
[word-splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html
