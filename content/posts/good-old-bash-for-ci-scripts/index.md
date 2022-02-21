---
title: "Good old bash for CI scripts"
date: 2022-02-20
draft: true
---

# Good-old Bash for CI/CD scripting

During many years I avoided learning shell scripting for the simple reason that I found it's syntax awkward and far away
from programing languages I was used to. Then I told to myself: _this thing has been around for so many years, it can't
be that hard_.

One day I made the decision to read [a free ebook I found in Amazon][amazon-book]... It took more courage
than time; in just a couple of hours I started to see that the awkward language had indeed some beautiful and well-thought
constructs that combined expressiveness and code brevity.

The small time investment rapidly paid off as soon as I started spending more time setting-up CI/CD processes, something
I do quite a lot recently and that I'll be talking about today.

[amazon-book]: https://www.amazon.com/Shell-Scripting-Automate-Command-Programming-ebook/dp/B015FZAXU6

## Why I like Bash for CI/CD scripts

There are some characteristics of Bash that make it ideal as a language for writing CI/CD scripts. These characteristics
aren't unique to Bash and you'll find them in other POSIX shell supersets but Bash offered the convenience of being
the default shell on many of the GNU/Linux distros I put my hands on.

### Ubiquity

Bash is almost everywhere when it comes to CI/CD. Whether you are running on containers or VMs is is likely that they
are GNU/Linux based, and Bash is likely going to be pre-installed by default.

Many CI/CD and automation platforms allow the use of shell scripts, and in particular Bash in their CI/CD configuration
files. Knowing Bash becomes very handy to quickly configure them as it is the _default shell_ for jobs that run on
GNU/Linux.

Let's say for example GitHub Actions workflows. When writing,

```yaml
...
jobs:
  job-foo:
    steps:
        - run: |
            echo "$FOO"
        env:
            FOO: ${{ inputs.foo }}
...
```

The above will run on Bash by default, as stated in their
[documentation](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idstepsshell):

> `bash`: The default shell on non-Windows platforms with a fallback to sh

That must be for a reason.

### No special syntax required to invoke commands or interact with file-system

Bash is great for _invoking commands_, manipulating files and handling inputs and outputs, which is often what you'll
be dealing with when doing CI/CD scripting.

Pick another language and you'll likely be _importing_ or _using_ packages, namespaces or modules to access the
functionality.

### Reduced set of dependencies

Bash is a short of _domain specific_ language focused on doing one thing. Usually scripts are written and certain tools
such as `tr`, `sed`, `tail` can be taken for granted and you don't do anything special to bring them in or keep them
updated... You just update the container or the distro where your CI/CD runners are running. These utilities have
existed for ages and have very stable interfaces: you can expect them to just work.

I often allow myself depending on other utilities such as `jq`, `curl` or `wget`, which are likely to be pre-installed
in CI/CD run environments. Normally the surface I consume from these utilities very small, which reduces the chances
CI/CD scripts breaking in time.

### Parameter expansion and word splitting

I found it awkward and difficult to remember at first, then I fell in love with it's brevity and usefulness.
[Parameter expansion][parameter-expansion] is like string interpolation with steroids.

Parameter expansion provides useful syntax to deal with null or unset variables:

|                     | parameter _set_ and _not null_ | parameter _set_ but _null_ | parameter _unset_ |
| ------------------- | ------------------------------ | -------------------------- | ----------------- |
| `{parameter:-word}` | parameter                      | word                       | word              |
| `{parameter-word}`  | parameter                      | null                       | word              |
| `{parameter:+word}` | word                           | null                       | null              |
| `{parameter+word}`  | word                           | word                       | null              |
| `{parameter:?word}` | parameter                      | error, exit                | error, exit       |
| `{parameter?word}`  | parameter                      | null                       | error, exit       |

An example could be invoking a command where I need to provide or omit one option of that command based on the presence
or absence of certain variables:

```bash
    dotnet publish \
        ${VERSION:+--version "$VERSION"} \
        .
```

Because of how Bash [word splitting works][], the _version argument_ is simply not there where the `VERSION` variable
is null or empty.

But there is more of it: 

* `{#parameter}` for replacing with the length of _parameter_.
* `{parameter#pattern}`, `{parameter##pattern}`, `{parameter%pattern}` or `{parameter%%pattern}` to remove parts of the
   string. For example, the `%` or `%%` are very useful to remove extensions from filenames.
* `{parameter/pattern/string}` for replacing patterns with _string_.

And these are just some examples. I agree the syntax is a bit difficult to remember and unlike any other found in other
programming languages, but it is consistent and allows for code brevity.

[parameter-expansion]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[shell-word-splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html

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