# multiglob
> yet another multi-pattern [node-glob][] wrapper

`multiglob` is another wrapper around the [glob][node-glob] module that allows matching of multiple patterns, to the likes of [multi-glob][], [simple-glob][] and [glob-manifest][].  Like `simple-glob`, it was inspired by the globbing patterns feature available in the [Grunt task runner][grunt].

`multiglob` allows you to pass a sequence of patterns that either expand or restrict the results.  You select the action to be done by prefixing the pattern with one of the following characters:
- `+`: add this pattern's matches to the list of results.  This is the default if no prefix is specified.
- `&`: keep only the results that match this pattern.
- `!`: exclude the results that match this pattern.  This is the converse of `&`.  If prefixing the first pattern, all not matching files are selected.
- `#`: comment.  Ignored.


## API

### Arguments

#### Pattern lists
In the API defined below, `...patterns` refers to a variable number of strings, which are the patterns to be matched.  Each pattern consists of an optional flag character followed by the pattern itself.  The flag character, one of `!`, `&`, `+` and `#`, determines how to merge the resulting matches with those produced by previous patterns:
- `+` adds the current matches to the previous ones,
- `&` results in only the matches that are present in both sets,
- `!` selects the previous matches that were not matched by the current pattern, and
- `#` marks a comment that is ignored.

Some of these flags operate by comparing the previous matches to the current ones.  When used in the first non-comment pattern, they may produce special or unexpected results:
- `!` selects all files not matching the given pattern
- `&` yields an empty list (because there are no results for it to intersect with)

If not specified (i.e. the first character in the pattern is none of the known flags), the operation defaults to union (`+`).

#### Options
Options objects are passed to `node-glob`.  All options are passed through except for `sync`: if it's set, it must not contradict the function being called (i.e. set to `true` when calling `multiglob.async` and vice-versa).  Also note that comments and negations are handled by `multiglob` itself and are always processed; the `nocomment`, `nonegate` and `flipNegate` options will not yield the desired effect.

### Functions

#### `multiglob.sync(...patterns, [options])`
Performs a glob search synchronously, returning an array of filenames matching the given pattern list.

#### `multiglob.async(...patterns, [options], [callback])`
Performs an asynchronous glob search.  `callback` is a standard Node.js callback function to which is passed a list of files matching the given pattern.  The return value is a [promise][promises-a+] for:
- the return value of the callback function, if it's provided;
- the matches list, otherwise.


[node-glob]:      https://github.com/isaacs/node-glob
[multi-glob]:     https://github.com/busterjs/multi-glob
[simple-glob]:    https://github.com/jedmao/simple-glob
[glob-manifest]:  https://github.com/jpillora/node-glob-manifest
[grunt]:          http://gruntjs.com/
[promises-a+]:    http://promisesaplus.com/
