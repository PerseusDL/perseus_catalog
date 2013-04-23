
module Blacklight::SolrHelper
  extend ActiveSupport::Concern
  include Blacklight::SearchFields
  # returns a params hash for finding a single solr document (CatalogController #show action)
  # If the id arg is nil, then the value is fetched from params[:id]
  # This method is primary called by the get_solr_response_for_doc_id method.
  def solr_doc_params(id=nil)
    #debugger
    id ||= params[:id]
    #id = solr_param_quote(id)
    #id = %("#{id}")
    p = blacklight_config.default_document_solr_params.merge({
      :id => id # this assumes the document request handler will map the 'id' param to the unique key field
    })

    p[:qt] ||= 'document'

    p
  end
end