---
layout: "../../../layouts/blog-layout.astro"
title: "I Just Solved Note Taking with a Simple Bash Script"
description:
    "I often need to quickly write stuff down. (don't we all?)
    I usually solved this by having an 'empty' instance of Neovim open in a
    separate window and switching to it whenever I encountered something I had
    to remember. I used Obsidian for more permanent note taking, but having
    to open Obsidian every time I needed to write a quick memo took way too
    long, so I relied too heavily on my 'quick Neovim notes', which very
    often led me to lose some pretty important
    (or at least convenient-to-have) data by accidentally closing it without
    saving."
image: {
    src: "/images/banners/note-apps-1.png",
    alt: "Bash script replacing Obsidian notes, Apple Notes, and Notion"
}
date: 2025-04-06
author: "Jakub Guštafik"
---

# The initial (sub-par) solution

At the start, it was enough for me to just `:w ~/memos/my-note.md`, or
something similar. (I prefer to write my notes in Neovim, that command
just means save to that path)

But this still wasn't the ideal solution. It was relatively cumbersome
and unorganized. My `~/memos` directory got real messy real fast, because I
still had no convenient way to access previous notes, so I just ended up
creating a whole lot of notes for the same thing.

Keep in mind, at this point, I wasn't even considering this as a note taking
option. (I used Obsidian for that) This was just the result of needing to
store (seemingly) unimportant information really quickly.
The need for retaining this information, however, eventually became a regular
occurence and I needed something more clever to do this job.

# The great idea

Okay, so let's see. The solution needs to be:

1. Quickly accessible from anywhere (to create or retrieve notes)
1. Organized, such that the required information can be retrieved at a glance

Note that I didn't explicitly think about these "requirements" at that point, these
were just the factors that I subconcously considered when making the solution.

At first, the obvious choice was to just make a `.bashrc` alias that started
Neovim in a certain directory with a certain filename. Once the alias line
reached about 100 characters, I decided to just make a bash script instead.

# The great solution

After some time spent testing and iterating, I landed on this 39 line script:

```bash
#!/bin/bash

memo_memo() {
    timestamp=$(date +%Y-%m-%d)

    if [ "$#" -gt 0 ]; then
        file_name="${timestamp}-$(echo "$@" | tr ' ' '-')".md
    else
        file_name="${timestamp}.md"
    fi
}

memo_find() {
    if [ "$#" -gt 1 ]; then
        file_name="$(find . -type f -name "*$2*" | fzf)"
    else
        file_name="$(find . -type f | fzf)"
    fi
}

original_dir=$(pwd)
memo_dir=~/memo

mkdir -p "$memo_dir"
cd "$memo_dir"

if [ "$1" == "-f" ]; then
    memo_find "$@"
else
    memo_memo "$@"
fi

if [ -n "$file_name" ]; then
    nvim "$file_name"
else
    echo "No file selected."
fi

cd "$original_dir"
```

> Feel free to use, modify, and share. Any credit given will be
> greatly appreciated, but is not required.
> In case there are any updates in the future, refer to this
> [**gist**](https://gist.github.com/kubgus/32ed5d543549d36e4206f14bbeed1a7e).

I didn't think much of it when I first wrote it. I was mostly glad that my
note-losing problem would be finally gone.

As I kept using it, however, I realized how powerful this script really was.
I was so impressed by things I didn't even consider when writing the original
script, that I eventually stopped needing Obsidian for most of my notes.

I am very convinced that to grasp the whole greatness of this script, one has
to first use it. However, in this second part of the article, I'd like to
explain how it works and why it is, in fact, so great.

# The great explanation

The `memo.sh` script, as I called it, has two main workflows. One is for
note creation and the other one is for retrieval.

## Creating notes

Just running the script without any arguments opens Neovim in your
`~/memo/` directory (this is easily configurable) with a file name
`YYYY-mm-dd.md`. (for example, today would be: `2025-04-06.md`)

Note that this doesn't yet create the file, that happens
only after you save the file with a simple `:w`. (or your prefered editor's way
of saving)

Some cool side effects of how this is implemented make it so that
when you run the script on the same day, the same file always opens.
This means that you aren't going to have a million files from the same day
or activity. But sometimes, we probably need to be able to create multiple notes
per day based on what we're doing.

> **Side note:** I will be using `memo` as the command to trigger the above script from
> here on. We will be going over setting up an alias to be able to access `memo`
> from anywhere later in this article.

Luckily, we can supply some arguments to our script to create multiple notes
per day. It works as follows:

```bash
memo activity # opens `YYYY-mm-dd-activity.md` in `~/memo`

memo another activity # opens `YYYY-mm-dd-another-activity.md` in `~/memo`
```

Similar to the previous example, supplying the same arguments on the same date
opens the editor on the same file, so we can easily return to our notes.

*"But what about notes that I didn't make today?"*, I hear you ask.
Don't worry, we are going to answer how to access notes from previous days
in this next section.

## Retrieving notes

Recently, I've been using *tmux* to organize my workspaces. While it it a
great standalone tool, what really got me productive with it was
[ThePrimeagen's tmux-sessionizer](https://github.com/ThePrimeagen/tmux-sessionizer),
which uses a fuzzy finder to search through your project directories and
start a *tmux* session in it.

This inspired me with my own tool, and so for retrieving files, I decided to use
the `fzf` command.

```bash
memo -f
```

Adding the `-f` (**f**uzzy **f**ind) flag after the `memo` command
opens a fuzzy finder with all the notes in our memo directory.

We can also narrow down the search by providing a single argument after `-f`
like this:

```bash
memo -f work
```

*This can obviously be done in the fuzzy finder itself, but it might be more
convenient in some situations and it wasn't difficult to implement.*

### "We have tags at home"

Having the ability to fuzzy search through your notes easily from anywhere
is awesome, but can still get pretty messy with incorrect enough file names.

That's why you should have a good naming scheme so you can access related
notes quickly. Luckily, this is very easy provided everything we know about
how we can use `memo`.

You can, of course, name your notes however you want, but the best way I've
found is to use the arguments you pass to `memo` as keywords/tags for easy
searching.

As an easy example, let's say that we are working on two projects at work.
The first tag for notes related to this could be `work` and the second ones
would be the specific project, like `backend` and `frontend`. (to keep it simple)

To create a new note for our backend project, we will run:

```bash
memo work backend # opens `2025-04-06-work-backend.md` (example date)
```

We basically passed in `work` and `backend` as tags that we can now use
to search for the note.

> **Another quick note:** I will be passing the search term as an argument
> to `memo -f` for simplicity. All of this can be done directly in the
> fuzzy finder interface. You can run `memo -f` with no additional arguments.

So now, to search through all of our work files, regardless of the project, we
can run:

```bash
memo -f work
```

On the other hand, we can search for notes on specific projects like this:

```bash
memo -f frontend
memo -f backend
```

If we had multiple projects named `backend` (let's say we also have a personal
backend project), we could narrow the search even more directly in the fuzzy
finder interface. (for example, searching for `work frontend`)

# The great setup

I genuinely believe this script is a game changer in terms of note taking
speed and convenience. But if this didn't convince
you yet, I invite you to try it. It's very easy to set up, and that's what
we're going to be going over in this last part of the article.

## Step 1: Get the script

*Copy it like you own it!* The easiest way to get the script is to copy it from
[**this gist**](https://gist.github.com/kubgus/32ed5d543549d36e4206f14bbeed1a7e)
and simply paste it into a new file wherever you want to store it on your system.

> I will be showing it as if the file is in my home directory saved as
> `~/memo.sh`. I believe if you've come this far, you are able to modify
> the following instructions to fit your specific case.

## Step 2: Allow execution

*This step is optional*, as you can always just run it with `sh`, but it's
usually more convenient to make it executable with `chmod`:

```bash
chmod +x memo.sh
```

## Step 3: Alias

Create an alias in your `.bashrc` (or `.zshrc` or whatever else there is)
that will allow you to run from anywhere:

```bash
sudo vim .bashrc # replace 'vim' with 'nano' if you don't know how to navigate Vim
```

And add the following line at the end:

```bash
alias memo="~/memo.sh"
# modify with your own path and
# add `sh ` at the start if you skipped the previous step
```

Now either restart your terminal or run:

```bash
source ~/.bashrc
```

And you should be done.

Let me know if you see any room for improvement in the comment section of my
[gist](https://gist.github.com/kubgus/32ed5d543549d36e4206f14bbeed1a7e) and
feel free to tell me how the tool's working out for you.

Thanks for reading!
