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


  def render_field_value (value, is_lang=false)
    value = value.split(";") if value =~ /;/
    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}    
    # retrieve the unabbreviated language code, but fall back to
    # original value when there is nothing to get
    value.map! { |lang| LANGUAGE_CODES[lang] || lang } if is_lang

    return value.map { |v| html_escape v }.join("<br />")
  end

  private

  # csv
  #   ang,English, Old (ca. 450-1000)
  #   eng,English
  # to hash
  #   { 'ang' => 'English, Old (ca. 450-1000)', 'eng' => 'English' }
  #
  def self.lang_codes_csv_to_hash
    csv = "#{Rails.root}/tmp_files/lang_codes.csv"
    File.readlines(csv).each_with_object({}) do |line, hsh|
      abbr, language = line.match(/^(.{3}),(.*)/).captures
      hsh[abbr] = language
    end
  end

  LANGUAGE_CODES = lang_codes_csv_to_hash
end
