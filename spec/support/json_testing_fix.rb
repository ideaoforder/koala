# when testing across Ruby versions, we found that JSON string creation inconsistently ordered keys
# which is a problem because our mock testing service ultimately matches strings to see if requests are mocked
# this fix solves that problem by ensuring all hashes are created with a consistent key order every time

module MultiJson
  self.engine = :ok_json

  def encode_with_ordering(object)
    # if it's a hash, recreate it with k/v pairs inserted in sorted-by-key order
    # (for some reason, REE 1.8.7 fails if we don't assign the ternary result as a local variable
    # separately from calling encode_original)
    new_object = if object.is_a?(Hash)
      sort_hash(object)
    elsif object.is_a?(Array)
      object.collect {|item| item.is_a?(Hash) ? sort_hash(item) : item}
    else
      object
    end
    encode_original(new_object)
  end

  alias_method :encode_original, :encode
  alias_method :encode, :encode_with_ordering
    
  private 
  
  def sort_hash(object)
    object.keys.sort.inject({}) {|hash, k| hash[k] = object[k]; hash}
  end
end
