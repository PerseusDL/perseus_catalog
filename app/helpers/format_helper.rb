#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================



# Helper mixin module -- adds additional export formats to the SolrDocument
# and provides a method for displaying format links on the SolrDocument displays
# in an alternate representations block 
module FormatHelper
  require "open-uri"
  
  def self.extended(document)
      if document.id =~ /^urn:cts:/
        document.will_export_as(:atom,"application/atom+xml")
      end
  end
  
  # implementing the atom feeds as an export format even though
  # they are not actually served by Blacklight in order to reserve
  # the possiblility that they might be in the future and to allow them
  # to be included as an rel alternate link in the Blacklight-supplied
  # atom feed opensearch results 
  def export_as_atom
    uri_path = get_canonical_format_uri('atom',self.id)
    begin
      raw_xml = open(uri_path).read()
      Nokogiri::XML::Document.parse(raw_xml)
    rescue
      # TODO return a skeleton feed that points at the canonical url ?
    end 
  end
  
  # returns the canonical uri the requested document id and format
  # only if the requested format is configured as canonical
  # otherwise returns nil
  def get_canonical_format_uri(format,id)
    if (BlacklightTest::Application.config.perseus_canonical_formats.grep(format))
      uri_parts = []
      uri_parts << BlacklightTest::Application.config.perseus_canonical_base_uri
      uri_parts << id
      uri_parts << format
      uri_path = uri_parts.join('/')
    else
      nil
    end
  end 
  
  # returns the canonical uri for the requested document id
  def get_canonical_uri(id)
      uri_parts = []
      uri_parts << BlacklightTest::Application.config.perseus_canonical_base_uri
      uri_parts << id
      uri_path = uri_parts.join('/')
  end 
  
  # renders html for display of a document's the canonical uri
  # in a block with the class .perseus_canonical_uri
  def render_canonical_link(document=@document, options = {})
    uri = get_canonical_uri(document.id)
    span_contents = ""
    span_contents <<  content_tag(:div,t('blacklight.views.perseus_canonical_uri_title'),{:class => 'title'}) 
    span_contents <<  content_tag(:div,uri,{:class => 'uri'}) 
    content_tag(:div,span_contents.html_safe,{:class=>'perseus_canonical_uri clearfix'})
  end
  
  # renders an html nav block for display of a document's export formats
  # based on Blacklight::BlacklightHelperBehavior.render_link_rel_alternates 
  def render_html_link_rel_alternates(document=@document, options = {})
    options = {:unique => false, :exclude => []}.merge(options)

    return nil if document.nil?

    seen = Set.new

    html = ""
    html << content_tag(:li,t('blacklight.views.perseus_alt_links_title'),:class => 'nav-header')
    document.export_formats.each_pair do |format, spec|
      unless( options[:exclude].include?(format) ||
             (options[:unique] && seen.include?(spec[:content_type]))
             )
          format_uri = get_canonical_format_uri(format,document.id)
          if (format_uri.nil?)
            format_uri = polymorphic_url(document) + "?format=#{format}"
          end 
          html << content_tag(:li, link_to(format, format_uri, {:title=>format}) )
  
        seen.add(spec[:content_type]) if options[:unique]
      end
    end
    html = content_tag(:ul,html.html_safe,:class=>'nav nav-list')
    return html.html_safe
  end

  
end