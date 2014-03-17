require! glob
require! Q: q

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
    if flag in <[! + &]>
      [flag, pattern.substr 1]
    else if flag isnt '#'
      ['+', pattern]

  # This is not a library's call to make.
  options.silent ?= true

  # Return the processed options.
  return [inputs, options]

# Join the accumulated glob matches and the ones given in the way
# specified by the operation flag.
add-matches = (results-so-far, operation-flag, matches) ->
  switch operation-flag
  | '+' => results-so-far     `union`    matches
  | '!' => results-so-far  `difference`  matches
  | '&' => results-so-far `intersection` matches

multiglob-async = (inputs, options) ->
  # Force asynchronous operation.
  options.sync = false
  # Perform all the globbings simultaneously.
  outputs = for let [flag, pattern] in inputs
    deferred = Q.defer!
    glob pattern, options, (err, matches) !->
      switch
      | err? => deferred.reject err
      | _    => deferred.resolve [flag, matches]
    deferred.promise

  # Then collect the results and join the matches.
  Q.all outputs .then (results) ->
    results.reduce (result, [flag, matches]) ->
      return add-matches result, flag, matches
    , []
  # Return a promise for the matches.

multiglob-sync = (inputs, options) ->
  # Force synchronous operation.
  options.sync = true
  # Perform the globbings in the order the patterns are specified,
  # sharing glob's path cache between calls.
  inputs.reduce (result, [flag, pattern]) ->
    glob-result = new glob.Glob pattern, options
    options.cache = glob-result.cache
    return add-matches result, flag, glob-result.found
  , []
  # Return the list of matches.


# Thrown when the `sync` option passed through the `options` object
# explicitly conflicts with the function being called.
class ConflictingOperationModeError extends Error
  name: \ConflictingOperationModeError
  (expected-state) ->
    super!
    [function-mode, option-state] = switch expected-state
    | \sync  => [ 'synchronous'  'false' ]
    | \async => [ 'asynchronous' 'true'  ]
    @message = "
      `sync` option set to #{option-state} but calling #{function-mode}
      version of multiglob
    "

module.exports =

  async: (...args) ->
    if typeof! args[*-1] is \Function
      # Callback provided
      callback = args.pop!
    if typeof! args[*-1] isnt \String
      # Options provided
      options = args.pop!
    else
      options = {}
    # Make sure the `sync` flag isn't explicitly set to `true`.
    if options.sync is true
      throw new ConflictingOperationModeError \async

    [inputs, options] = process-input args, options
    promise = multiglob-async inputs, options
    if callback?
      promise.then (callback null, _), callback
    else
      promise

  sync: (...args) ->
    if typeof! args[*-1] isnt \String
      # Options provided
      options = args.pop!
    else
      options = {}
    # Make sure the `sync` flag isn't explicitly set to `false`.
    if options.sync is false
      throw new ConflictingOperationModeError \sync

    [inputs, options] = process-input args, options
    multiglob-sync inputs, options
