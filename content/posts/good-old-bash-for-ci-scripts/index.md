---
title: "Things you should know if you are using Bash in your CI scripts"
date: 2022-02-20
draft: true
---

# 

> __TL; DR;__: If you can't avoid Bash put some time to learn some of the killing features it has to offer.

## Why do we write CI logic in Bash

There are some characteristics of Bash that make it ideal as a language for writing CI code. Many of this characteristics are not exclusive
property of Bash and apply to other shells, but more often than not `Bash` is the default.

So what is so good about writing Bash?

### Ubiquity

Bash is almost everywhere where you have a Unix based system. Many CI jobs run on linux-based containers or Virtual Machines where
Bash is either available out of the box or at the reach of one instal command. 

Even Windows practitioners can also find it nowadays with the rise of [Windows Linux Subsystem]() or tools such as [msys2](), [cygwin]() or even
[git for windows]().

I don't know of any CI/CD platforms that doesn't support inlining Bash scripts when defining jobs: from Jenkins, to GitHub actions, TeamCity, Gitlab CI
or Bitbucket Pipelines: it's always there.

### No special syntax required to invoke commands

Bash is great for _invoking commands_, manipulating files and handling inputs and outputs, which is often what you'll
be dealing with when doing CI logic: _call this tool_, transform _its output_ and _pass it along to this other tool_.

Invoking a tool is just as simple as writing the tool name. Pick another language and you'll likely be importing some 
packages, namespaces or modules to access the same functionality.

### Reduced set of dependencies

Bash is a short of _domain specific_ language focused on doing one thing. Often accomplishing something requires the use of other POSIX utilities
such as `tr`, `cut`, `sed`, ... This aren't part of Bash, but you can count on them if you are on a POSIX compatible environment.

These tools have existed for decades and have become very mature and have often stable interfaces, at least for as long you stick to POSIX compatibility.

### Piping

I love _piping_. It's kind of the functional way of dealing with streams of data vs its imperative counterpart, which would be to write a for loop. 
What I like about piping is that you can divide problems into many small problems, and it allows you to read the sequence of transformations from left to right,
which feels natural:

```
cat test-times | cut -d '\t\ -f 1 | sort | uniq   # Get unique test names from the test-times file
```

### Bash is concise

### Parameter expansion and word splitting

I found it awkward and difficult to remember at first. I still struggle to remember it to be honest, but I admire its conciseness.
[Parameter expansion][parameter-expansion] is like string interpolation on steroids. And provides a useful syntax to deal with null or unset variables:

|                     | parameter _set_ and _not null_ | parameter _set_ but _null_ | parameter _unset_ |
| ------------------- | ------------------------------ | -------------------------- | ----------------- |
| `{parameter:-word}` | parameter                      | word                       | word              |
| `{parameter-word}`  | parameter                      | null                       | word              |
| `{parameter:+word}` | word                           | null                       | null              |
| `{parameter+word}`  | word                           | word                       | null              |
| `{parameter:?word}` | parameter                      | error, exit                | error, exit       |
| `{parameter?word}`  | parameter                      | null                       | error, exit       |

If you think that i shard to remember, you are not alone. I use the following mnemonics:

* I associate `-` to what happens when `parameter` is _missing_. So _put `word` if parameter is _missing_.
* `+` tells about what to do if `parameter` is _present_. The `+` to me indicates presence.
* `?` is asking _has it been set_?
* By default null is considered just _one more value_. With `:` we can alter that behavior to do the opposite.

The forms I use the most are `:-`, `:+` and `:?`, since normally `null` almost always represents _unset_ to me.

__Example 1: Validating required variables__:

```bash
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:?Missing GITHUB_WORKSPACE variable, are you running from CI?}"
```

__Example 2: Providing reasonable defaults:

```bash
OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/stdout}"
```

__Example 3: Passing optional arguments__

Your scripts provide an abstraction over certain commands. Sometimes inputs to your scripts determine which arguments shall
be set.

For example, let's say you have an scrip that takes an input `VERSION` as an environment variable and that should determine whether
you pass a  `--version "$VERSION"` argument to a certain command:

```bash
   dotnet publish ${VERSION:+--version "$VERSION"} --no-build .
```

If `VERSION` has ben set, the `{ ... }` expression will be substituted with `--version "$VERSION"`. If it is `null` or `unset` nothing will be
substituted. Notice that __${...}__ is not within quoted. Because of how [word splitting](word-splitting) works in Bash it would just be as 
if you would've substituted the whole thing by a space.

But there is more of it: 

* `{#parameter}` for replacing with the length of _parameter_.
* `{parameter#pattern}`, `{parameter##pattern}`, `{parameter%pattern}` or `{parameter%%pattern}` to remove parts of the
   string. For example, the `%` or `%%` are very useful to remove extensions from filenames.
* `{parameter/pattern/string}` for replacing patterns with _string_.

And these are just some examples. This provides very concise syntax for doing the typical string manipulations that are involved in CI logic.

[parameter-expansion]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[word-splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html

## How I use Bash for CI/CD

### I simply don't care about portable shell scripting

### I avoid writing logic directly on CI/CD Yamel configuration

### The environment variable vs argument dilemma 

### It is important to distinguish between gluing scripts and CLI applications

### Delegate input validation

### Avoid depending on specific CI/CD platforms 

## How I make my scripts testable

## Is this for everyone?

I believe every developer could benefit of learning Bash and be able to understand most of it's idioms. It isn't that
hard if you put some time in it.

In today's world of fast-paced development it is more often than not to see programmers that avoid Bash at all costs, 
which is a pity because Bash has something to offer to them: it is king in sysadmins's land and I think it has it's space as
_plumbing code_ for CI/CD scripting. It allows for code brevity, rapid prototyping and 

I know what they say, that code is _read far more often than it's written_, and I agree. I wouldn't write any complex 
application with it (even if some folks do: for example see [bocker](https://github.com/p8952/bocker) a Bash docker 
implementation or [this x86 assembler](https://lists.gnu.org/archive/html/bug-bash/2001-02/msg00054.html)).

But when it comes to wiring-up commands, manipulating strings or quickly setting up CI/CD configuration, Bash 
kick-asses. Personally, I find I'm a more complete developer knowing Bash that not knowing it, and it feels great to
not have succumbed to the fear of it's unortodox syntax. You know what they say: _if you run away from your fears they
will eventually become nightmares_.

##

[amazon-book]: https://www.amazon.com/Shell-Scripting-Automate-Command-Programming-ebook/dp/B015FZAXU6