require! glob
require! Promise: promise

# Array operation helpers.
intersection = (a, b) -> a.filter (in b)
difference   = (a, b) -> a.filter (not in b)
union        = (a, b) -> a.concat difference b, a


# Validate and process the input arguments into a form suitable to
# the multiglob functions.
process-input = (patterns, options={}) ->
  # Check if at least one pattern was specified.
  if patterns.length is 0
    throw new Error "no patterns provided"

  # Work around isaacs/node-glob#62 by matching the whole tree first.
  if patterns[0][0] is '!'
    patterns.unshift '**/*'

  # Check if the patterns are valid and split them into
  # `(flag, pattern)` pairs.
  inputs = for pattern in patterns
    if typeof! pattern isnt \String
      throw new TypeError "pattern is not a string"
    if pattern.length is 0
      throw new Error "pattern is an empty string"

    flag = pattern[0]
    if flag in <[+ & !]>
      operation = switch flag
      | '+' => union
      | '!' => difference
      | '&' => intersection
      [operation, pattern.substr 1]
    else if flag isnt \#
      [union, pattern]

  # This is not a library's call to make.
  options.silent ?= true

  # Return the processed options.
  return [inputs, options]

multiglob-async = (inputs, options) ->
  # Perform all the globbings simultaneously.
  outputs = inputs.map ([operation, pattern]) ->
    resolve, reject <-! new Promise _
    glob pattern, options, (err, matches) !->
      | err? => reject err
      | _    => resolve [operation, matches]

  # Then collect the results and join the matches.
  Promise.all outputs .then -> it.reduce (result, [operation, matches]) ->
    return operation result, matches
  , []
  # Return a promise for the matches.

multiglob-sync = (inputs, options) ->
  # Perform the globbings in the order the patterns are specified,
  # sharing glob's path cache between calls.
  inputs.reduce (result, [operation, pattern]) ->
    glob-result = new glob.Glob pattern, options
    options.cache = glob-result.cache
    return operation result, glob-result.found
  , []
  # Return the list of matches.


# Check if `options.sync`, if set, does not conflict with the caller's
# operation mode (sync or async), then set it to the expected value.
set-sync-option = (function-mode, options) !->
  expected-option-state = switch function-mode
  | 'synchronous'  => true
  | 'asynchronous' => false
  if options.sync is !expected-option-state
    throw new Error "
      `sync` option set to #{options.sync} but calling #{function-mode}
      version of multiglob
    "
  options.sync = expected-option-state


module.exports =

  async: (...args) ->
    if typeof! args[*-1] is \Function
      # Callback provided
      callback = args.pop!
    if typeof! args[*-1] isnt \String
      # Options provided
      options = args.pop!

    [inputs, options] = process-input args, options
    set-sync-option \asynchronous options
    promise = multiglob-async inputs, options
    if callback?
      promise.then (callback null, _), callback
    else
      promise

  sync: (...args) ->
    if typeof! args[*-1] isnt \String
      # Options provided
      options = args.pop!

    [inputs, options] = process-input args, options
    set-sync-option \synchronous options
    multiglob-sync inputs, options
