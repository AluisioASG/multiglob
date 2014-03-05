require! glob

# Array operation helpers.
intersection = (a, b) -> a.filter (in b)
difference   = (a, b) -> a.filter (not in b)
union        = (a, b) -> (a ++ b).filter (e, i, arr) -> (arr.indexOf e) is i


multiglob = (options, ...patterns) ->
  if typeof! options is \String
    # `options` is actually a pattern; use the default options and
    # add `options` to the patterns.
    patterns.unshift options
    options = {}
  # Always perform the globbing synchronously.
  options.sync = true

  results = []
  for pattern in patterns
    # Remove the operation flag from the pattern, defaulting to
    # inclusion if it's not specified.
    if pattern[0] in <[! + &]>
      [flag, pattern] = [pattern[0], pattern.substr 1]
    else
      flag = '+'
    # Perform the globbing and update the cache.
    result = new glob.Glob pattern, options
    options.cache = result.cache
    # Process the matches.
    results = switch flag
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
