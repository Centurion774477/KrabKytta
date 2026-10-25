# KrabKytta
KrabKytta is style checker for [KrabbaScript](https://github.com/khytryy/krabbascript). It's inspired by RuboCop but a bit less pervasive.

The rules enforced by KrabKytta are very sensible and help you to avoid write-only code.

First, I'll provide a run-down of the rules and then I'll explain how to use KrabKytta for your projects.

## Rules

There are three rules that you can change with a krabkytta.yaml file. These rules are:

- maximum character limit for lines
- variable naming scheme (camelCase, snake_case)
- deprecated keywords

I wanted to give teams control over these features, since opinions may vary between teams.

If you do not provide a config file, then the respective defaults will be:
- 120
- snake_case
- none

Moving on, now I'll go over the rules present in every test —— these cannot be changed or overidden in any way.

Lines cannot have more than one expression: 
```
val foo: I32 = “bar”; print(foo);
```

Val should be used by default — especially if the variable isn’t reassigned
```
var year: I32 = 1704
# no reassignment of year
```

The usage of `var` should signal that the given variable will be reassigned later on;
it's confusing to use `var` and not reassign it.

While and repeat block conditions should not have ! operators.

Because KrabbaScript gives you more than one way to write a loop, 
there is no reason to use negative conditions in loops.

Instead of:

```
repeat {
	cook_food()
} until !hungry
```

You should write:

```
while hungry {
	cook_food()
}
```

This goes both ways —— negative while loops should be repeat..until loops; negative repeat..until loops should be while loops.


Avoid when blocks with only one condition

This is improper:
```
when language {
  == "Elixir" do celebrate!
}
```

When blocks should always have two or more conditions.

The better way to write this is with a single `if` statement:

```
if language == "Elixir" {
  do celebrate!
}
```

Variable definition without assigning a value is improper:

```
val year: I32
```

Try to always provide a default value. For numbers, you can use 0; for arrays, you can use []; for strings, you can use "".
```
val year: I32 = 0
```

## Using KrabKytta

KrabKytta is quite easy to use since it requires no commands or flags. Simply invoke the file and pass your test file.

For example:

```
ruby krabkytta.rb file.ks
```

You could also add KrabKytta to your path to make invocation even easier.

## Ending

One thing I'd like to clear up is that KrabKytta only points out problems—
it won't fix them for you.

I hope you enjoy KrabKytta. Cheers!
