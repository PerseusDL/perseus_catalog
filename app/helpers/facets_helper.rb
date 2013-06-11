module FacetsHelper
  include Blacklight::FacetsHelperBehavior

#selects the correct non-tokenized facet for alphabetic range finding  
  def facet_buttons_type(type)
    q_type = nil
    case type
      when "auth_facet"
        q_type = "auth_no_token"
      when "work_facet"
        q_type = "work_no_token"
      when "tg_facet"
        q_type = "tg_no_token"      
    end
    return q_type
  end

#populates the alphabetical range links at the bottom of the author group, author, and works facets
  def render_facet_alph_btns(type, range)
    q_field = facet_buttons_type(type)
    btns = ""
    (range).each do |let|      
      btns << (link_to let, add_alph_sort_params(q_field, type, let), :class => "btn")
    end
    return content_tag(:div, btns.html_safe, :class => "alpha btn-group")
  end

  def add_alph_sort_params(q_field, type, letter)
    lett_arr = ('A'..'Z').to_a
    lett_arr << '*'
    next_index = lett_arr.index(letter) + 1

    #Delete the page for moving between letters
    params.delete('facet.page')

    params.merge(:id => type, :action => "facet", :q => "#{q_field}:[#{letter} TO #{lett_arr[next_index]}]")
  end

  def render_facet_value(facet_solr_field, item, options ={})    
    is_lang = facet_solr_field =~ /lang/i 
    (link_to_unless(options[:suppress_link], render_field_value(item.label, is_lang), add_facet_params_and_redirect(facet_solr_field, item), :class=>"facet_select") + " " + render_facet_count(item.hits)).html_safe
  end

#Overriding original to add the removal of alphabetic pagination in the :q field
  def add_facet_params_and_redirect(field, item)
    new_params = add_facet_params(field, item)

    # Delete page, if needed. 
    new_params.delete(:page)

    #Delete q, if needed
    new_params.delete(:q)

    # Delete any request params from facet-specific action, needed
    # to redir to index action properly. 
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"
    new_params    
  end

end