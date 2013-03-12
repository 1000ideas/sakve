class String
  def query_tokenize(*args)
    options = args.extract_options!
    search_type = args.shift
    min_length = options.delete(:min_length) || 2
    type_separator = options.delete(:type_separator) || ':'

    self.scan(/'[^']+'|"[^"]+"|(?:[^[:blank:][:punct:]]|:)+/).map do |token|
      type, _, word = token.tr(%('"), '').partition(type_separator)
      Rails.logger.debug "'#{type}' - '#{word}'"
      if word.blank?
        word, type = type, nil
      else
        type = type.to_sym
      end
      word if (type == search_type || type.nil?) && word.length > min_length
    end.compact.uniq
  end
end
