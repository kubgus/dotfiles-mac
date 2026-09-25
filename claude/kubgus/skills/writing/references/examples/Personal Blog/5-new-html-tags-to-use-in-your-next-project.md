---
layout: "../../../layouts/blog-layout.astro"
title: "5 New HTML Elements To Use In Your Next Project"
description:
    "The are approximately 140 elements available in HTML. But how many
    do you actually use in your projects? Not knowing your HTML tags means
    you might be unnecessarily overcomplicating your codebase and adding
    more JavaScript and CSS than needed to complte tasks that HTML already
    has built-in elements for. This article provides a look into the
    lesser-known tags in HTML that many overlook, and that will help you
    make you next project much more optimized and effective."
image: {
    src: "/images/banners/html-coder-1.webp",
    alt:
        "ChatGPT: Generate an image of a cool programmer coding in
        HTML getting over beginner mistakes"
}
date: 2024-10-18
author: "Jakub Guštafik"
---

## `<details>`

<a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details" target="_blank">MDN Reference</a>

The `<details>` element is a plain HTML way to create collapsible
elements instead of replicating the functionality in JavaScript.

Inside `<details>`, you can use the `<summary>` element to define the
title of the collapsible section.

```html
<details>
    <summary>Click me!</summary>
    Additional information...
</details>
```

<details>
    <summary>Click me!</summary>
    Additional information...
</details>

## `popover`

<a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/popover" target="_blank">MDN Reference</a>

While popovers aren't really their own tags, they can be used to create
popups and dialogs without JS.

Use the `popover` attribute to make the element a popover.
Use the `popovertarget` attribute with the value of the popover's `id`
on a clickable element to make it activate the popover on click.

```html
<button popovertarget="my-popover">Open Popover</button>
<div popover id="my-popover">This wasn't here before!</div>

<style>
    :popover-open {
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }
</style>
```

<div>
    <button popovertarget="my-popover">Open Popover</button>
    <div popover id="my-popover">This wasn't here before!</div>
    <style>
        :popover-open {
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
        }
    </style>
</div>

## `<noscript>`

<a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/noscript" target="_blank">MDN Reference</a>

The `<noscript>` element is used to display certain content only if
the user has disabled Javascript in their browser.

The `<noscript>` element can be used in both `<head>` and `<body>`.

```html
<noscript>
    <p>You did it!</p>
</noscript>
```

**Disable Javascript in your browser to see the result:**

<noscript>
    <p>You did it!</p>
</noscript>

## `<address>`

<a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/address" target="_blank">MDN Reference</a>

This is one of the more boring elements, but it's worth discussing because
many people add contact sections to their websites, but not many use this
element.

The `<address>` element is used to display contact information for the
current page. It doesn't make a visual difference, but it helps add
context to your page.

This will help make your website more accessible to screen readers and
crawlers, which will rank your website higher in Google searches.

```html
<address>
    <p>Email me at:</p>
    <a href="mailto:business@gustafik.com">business@gustafik.com</a>
</address>
```

<address>
    <p>Email me at:</p>
    <a href="mailto:business@gustafik.com">business@gustafik.com</a>
</address>

## `<meter>` & `<progress>`

<div>
    <a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meter" target="_blank">MDN Reference 1</a>
    <br/>
    <a href="https://developer.mozilla.org/en-US/docs/Web/HTML/Element/progress" target="_blank">MDN Reference 2</a>
</div>

The `<meter>` and `<progress>` elements are used to display progress bars
with a value and a range of possible values.

The difference between the two elements is that the `<meter>` element
also defines the visual appearance of the progress bar with attributes
like `high`, `low`, and `optimum`.

```html
<label for="fuel">Meter:</label>
<meter id="fuel" min="0" max="100" low="33" high="66" optimum="80" value="50"></meter>

<label for="progress">Progress:</label>
<progress id="progress" value="50" max="100"></progress>
```

<label for="fuel">Meter:</label>
<meter id="fuel" min="0" max="100" low="33" high="66" optimum="80" value="50"></meter>

<label for="progress">Progress:</label>
<progress id="progress" value="50" max="100"></progress>

<input type="range" id="range" min="0" max="100" value="50"></input>


<script>
    const range = document.getElementById("range");
    range.addEventListener("input", () => {
        document.getElementById("progress").value = range.value;
        document.getElementById("fuel").value = range.value;
    });
</script>

```html
// code for the interactive slider

<input type="range" id="range" min="0" max="100" value="50"></input>

<script>
    const range = document.getElementById("range");
    range.addEventListener("input", () => {
        document.getElementById("progress").value = range.value;
        document.getElementById("fuel").value = range.value;
    });
</script>
```
