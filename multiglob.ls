require! glob

# Array operation helpers.
intersection = (a, b) -> a.filter (in b)
difference   = (a, b) -> a.filter (not in b)
union        = (a, b) -> (a ++ b).filter (e, i, arr) -> (arr.indexOf e) is i


multiglob = (...patterns, options) ->
  if typeof! options is \String
    # `options` is actually a pattern; use the default options and
    # add `options` to the patterns.
    patterns.push options
    options = {}
  # Always perform the globbing synchronously.
  options.sync = true
  # Ignore comments.
  options.nocomment = false

  # Work around isaacs/node-glob#62 by matching the whole tree first.
  if patterns[0]?[0] is '!'
    patterns.unshift '**/*'

  results = []
  for pattern in patterns
    # Remove the operation flag from the pattern, defaulting to
    # inclusion if it's not specified.
    if pattern[0] in <[! + & #]>
      [flag, pattern] = [pattern[0], pattern.substr 1]
    else
      flag = '+'
    # Perform the globbing and update the cache.
    result = new glob.Glob pattern, options
    options.cache = result.cache
    # Process the matches.
    results = switch flag
    | '#' => results
    | '!' => results `difference` result.found
    | '+' => results `union` result.found
    | '&' => results `intersection` result.found
  return results


module.exports = (...args, callback) ->
  process.nextTick !->
    try
      results = multiglob ...args
      callback null, results
    catch err
      callback err
module.exports.sync = multiglob
