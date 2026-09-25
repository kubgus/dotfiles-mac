---
layout: "../../../layouts/blog-layout.astro"
title: "Constant Pointers in C++"
description: "This short guide outlines the intricacies of constant pointers in C++ and explains how they can be used."
date: 2024-09-10
author: "Jakub Guštafik"
---

The `const` keyword may seem simple at first - it makes any variable constant,
meaning it can't be modified later in your code. However, there are many
cases where the use of `const` isn't so clear.

## The problem

```cpp
const int *a = &b;
```

What exactly is constant here? Does this mean you cannot modify the value
or the pointer? Or both?

## The solution

We can start by defining how we declare pointer variables:

```
<pointer type> *<variable name> = <value>;
```

We can intuitively deduct, that in the previous statement, we are clearly
creating a pointer of type `const int`. This means that the resulting
variable's underlying value will be constant, but the pointer will be
modifiable.

```cpp
*a = 6; // not allowed
a = &c; // allowed
```

We can also choose to write this differently with the same functionality:

```cpp
int const *a = &b; // same as `const int *a = &b;`
```

We can achieve the opposite effect by declaring the following variable:

```cpp
int *const a = &b;
```

The above variable's underlying value can be modified, but the pointer
**cannot be reassigned**.

You can also combine these const rules to make a *const behemoth* that
has a constant value and cannot be reassigned:

```cpp
const int *const a = &b;
```
