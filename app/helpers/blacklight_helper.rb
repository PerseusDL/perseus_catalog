module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def render_index_field_value args
    value = args[:value]
    if args[:field] == "work_lang"
    end
    if args[:field] and blacklight_config.index_fields[args[:field]]
      field_config = blacklight_config.index_fields[args[:field]]
      value ||= send(blacklight_config.index_fields[args[:field]][:helper_method], args) if field_config.helper_method
      value ||= args[:document].highlight_field(args[:field]) if field_config.highlight
    end

    value ||= args[:document].get(args[:field], :sep => "; ") if args[:document] and args[:field]
    if args[:field] =~ /lang/
      render_field_value(value, true)
    else
      render_field_value(value, false)
    end
  end

  def render_document_show_field_value args
    value = args[:value]

    if args[:field] and blacklight_config.show_fields[args[:field]]
      field_config = blacklight_config.show_fields[args[:field]]
      value ||= send(blacklight_config.show_fields[args[:field]][:helper_method], args) if field_config.helper_method
      value ||= args[:document].highlight_field(args[:field]).map { |x| x.html_safe } if field_config.highlight
    end

    value ||= args[:document].get(args[:field], :sep => "; ") if args[:document] and args[:field]
    if args[:field] =~ /lang/
      render_field_value(value, true)
    else
      render_field_value(value, false)
    end
  end

#want to find a way to override this so that I can catch the language codes and turn them into full words
  def render_field_value (value, is_lang=false)
    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}

    if is_lang
      file_sys = Rails.root
      codes = File.read("#{file_sys}/tmp_files/lang_codes.csv")
      codes_arr = codes.split("\n")
      pair = codes_arr.each {|cell| break cell.split(",") if cell =~ /#{value},/}
      value = pair[1] unless pair.empty?
    end

    return value.map { |v| html_escape v }.join(field_value_separator).html_safe
  end


end
