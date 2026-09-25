# InVenture Mind - What Would You Study

**Question:** "If you could study anything in the world at university, what would it be? And why?"

**Situation:** He gave one line of raw input and asked for it written in his voice:

> "Ai research because of the complexity and space for improvement in the field. i would like to
> explore ai model-focused chips (chips designed to run single models efficiently instead of big
> computers running the model.)"

Different problem from the other two: not editing his prose but generating it from a sentence.
The risk here is inventing biography to fill the space.

---

## Sent

> AI research, specifically the hardware side of it. What pulls me toward it is that the field is
> young enough that the obvious answers probably are not the right ones yet. Today we run models
> on general-purpose hardware: large datacenters full of chips that can run anything, which means
> they are not especially good at running any one thing. I want to work on the opposite approach -
> chips built around a single model, with the weights sitting on the chip itself instead of being
> streamed to it from memory. Most of the cost of running a model now is moving data around rather
> than computing on it, so there is a lot of room left in that direction. The obvious objection is
> that models change far faster than silicon can be designed, and that is the part I find most
> interesting. It is a real constraint that nobody has solved. I taught myself most of what I know
> about software outside of school, and embedded work is what I keep coming back to. I like
> problems where the limits are physical ones.

## Why it works

- **The counter-argument is the best part.** Naming why model-specific silicon is hard (models
  iterate in months, tape-outs take years) is what separates someone who follows the field from
  someone who liked the idea. Enthusiasm is free; a named constraint is not.
- **His reasoning, sharpened, not replaced.** "Complexity and space for improvement" became the
  concrete version of the same claim - inference is memory-bandwidth-bound, so keeping weights on
  chip is where the headroom is. Same thought, made checkable.
- **Answered "why", not "what".** No list of coursework. They asked for the reason.
- **Two sentences of personal grounding, not a paragraph.**

## The boundary that mattered

The first attempt ended *"I got into software through embedded projects rather than through a
classroom."* That is not in the profile - it says self-taught, and lists embedded among his
interests. Plausible, unverified, and the kind of detail he would have to defend in an interview.
It was softened to what is actually known ("I taught myself most of what I know about software
outside of school") and **flagged back to him to confirm or cut.**

Rule: when writing as him, a fact may be *used* or *softened*, never *extrapolated*. If the
sentence needs a fact that is not in evidence, hand it back as a bracket or a flag rather than
filling the gap with something that fits.

## Offered and left out

Naming Groq, Cerebras or Etched would show he follows the field rather than having had the idea
independently - offered as optional, with the caveat that he would need to be able to discuss it.
Offer the credential-raising detail, let him decide whether he wants to defend it.
