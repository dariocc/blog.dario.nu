---
title: good-old-bash-for-ci-scripts
date: 2022-12-06
draft: true
---

# Good Ol' Bash for CI

Bash, loved by some, hated by others...As for my self, in Facebook terms I'd
describe my relationship with Bash as _complicated_: I do appreciate its
conciseness, string manipulation capabilities and ability to directly invoke
commands, but I also suffer its quirks and struggle sometimes to remember all of
its syntax, specially after a period of programming in other languages.

But like it or not Bash is _a_ if not the _king_ of CI logic... It's ubiquitous
and almost any worthy CI system allows embedding bash logic into their CI jobs:
GitLab CI, GitHub Actions, Bitbucket Pipelines, Jenkins, ... you name it Even if
in the cases you can choose your shell Bash is often the default.

So rather than _fighting it_, let's fight it. I've summarized some practical
advise with regards to the use and abuse of Bash logic for CI.

Before that, let's remember #1 advice of
[the Pragmatic Programmer][the-pragmatic-programmer] (a book I can highly
recommend):

> _Care about your craft: Why spend your life developing software unless you
> care about doing it well_.

## Start learning some POSIX shell scripting first if you aren't familiar with the basis

I've been using Linux since 2012, yet I didn't take the trouble of learning
shell scripting until summer 2017. What pushed me to learn it was that I had
recently changed job and I started to have to interact more frequently with
linux-based remote machines running on cloud services and the number of
automation I needed increased.

All it took for me was one bored summer day in the
[Lomma Beach](https://www.tripadvisor.com/Tourism-g1898350-Lomma_Skane_County-Vacations.html),
a Kindle and a
[Free ebook](https://www.amazon.com/Shell-Scripting-Automate-Command-Programming-ebook/dp/B015FZAXU6).

I had written shell scripts before that, but syntax for quotes, variables and
control-flow statements felt always awkward.

That simple reading really made a difference. For example, learning that the
bracket `[` was a _command_ (equivalent to `test`) rather than a language
construct was the key for me to understand the apparently weirdness of
`if [ ... ]` expressions.

Starting this way instead of jumping directly into Bash had the advantage that
it greatly reduced the amount of concepts I had to learn at once, and in fact
the book was short enough for me to complete it in the same day I downloaded it.

The way to learn _Bashisms_ has been more on-demand; reading documentation and
stack overflow answers as needed arouse. In a way I can say I have not yet
completed my learning.

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

But now we used `"`, how come? I'm with you, it feels weird, but that is the way
it works: `"${colors[@]}"` is the way to expand `colors` elements double quoting
each element, i.e.:

```bash
for color in "red" "yellow" "green" "antique white"
do
    echo "$color"
done
```

My only advise is to stop thinking of _text within quotes_ as _strings_ with
your C#, Python, Java, C++,... eyes. Learn _the bash way_ to look at it.

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
is frequent enough so as to want to avoid it.

We can use `local` to restrict the scope of a variable:

```bash
say_hello() {
    local who
    ...
}
```

Now the call to `say_goodbye` would return a non zero exit code and, because it
is the last line of the script, the script will fail.

Using `local` can give you peace of mind.

By the way, `local` is a _bash built-in_ not a syntax keyword, which means it
will return 0 or 1. This has some implications. Consider the following:

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

- I associate `-` to what happens when `parameter` is _missing_. So \_put `word`
  if parameter is _missing_.
- `+` tells about what to do if `parameter` is _present_. The `+` to me
  indicates presence.
- `?` is asking _has it been set_?
- By default null is considered just _one more value_. With `:` we can alter
  that behavior to do the opposite.

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

Your scripts provide an abstraction over certain commands. Sometimes inputs to
your scripts determine which arguments shall be set.

For example, let's say you have an scrip that takes an input `VERSION` as an
environment variable and that should determine whether you pass a
`--version "$VERSION"` argument to a certain command:

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

But there is more of it:

- `{#parameter}` for replacing with the length of _parameter_.
- `{parameter#pattern}`, `{parameter##pattern}`, `{parameter%pattern}` or
  `{parameter%%pattern}` to remove parts of the string. For example, the `%` or
  `%%` are very useful to remove extensions from filenames.
- `{parameter/pattern/string}` for replacing patterns with _string_.

And these are just some examples. This provides very concise syntax for doing
the typical string manipulations that are involved in CI logic.

## There is no shame in not being compliant with POSIX

Bash is a superset of POSIX shell and as such you might be tempted to write
_portable code_. I rarely find this useful for usual desktop unix based
operative systems. And doing some common things such as _extracting the basename
of a file_ or _the directory_ get much more complicated without certain Bash
built-ins.

Bash is the norm and not the exception and if it happens to not be the default
shell of your OS, I expect you to install it :). I don't care if you prefer
`Zsh`.

This is even truer if we are talking about CI (which we are), where you normally
have control over what tools are available in the hosts of the runners of your
CI jobs.

## Strive to write scripts you can manually run

### Accepting input as environment variables

### Accepting input from a CLI

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
```

set -- "${POSITIONAL\[@\]}" # restore positional arguments

## Show your manners when invoking commands

Compare this:

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

To:

```bash
command --arg-1 arg-1-value --arg-2 arg-2-value --arg-4 arg-4-value --arg-5 arg-5-value --arg-6 arg-6-value --arg-7 arg-7-value --arg-8 arg-8-value
```

Now thing what would happen if those argument values where long urls, or
sub-shells invocations...

When a command takes more than 3 arguments, or the value of those arguments is
an expression `$(...)` the first version is much more readable than the second.
The price to pay: 2-3 keystrokes per argument.

This makes life simpler also when diffing both split and inline views.

### If you feel the need of writing a CLI utility: look somewhere else

It is possible to process arguments. I've done it, and every time I've hated it.

I've learned to accept _environment variables_ as the way to pass information to
CI scripts.

The only _but_ I have about this approach is that I can technically end-up with
_accidentally set variables_. To avoid that, always set ALL variables from your
script _wrapper_.

In my opinion, CI logic that takes more

What is the magical number? I'll say: 5

## Is this for everyone?

I believe every developer could benefit of learning Bash and be able to
understand most of it's idioms. It isn't that hard if you put some time in it.

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

[parameter-expansion]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[the-pragmatic-programmer]: https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition
[word-splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html
