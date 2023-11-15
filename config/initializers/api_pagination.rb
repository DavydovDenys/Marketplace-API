# frozen_string_literal: true

ApiPagination.configure do |config|
  config.paginator = :kaminari
  config.total_header = 'X-Total'
  config.per_page_header = 'X-Page-Size'
  config.page_header = 'X-Page'
  config.response_formats = [:json]
  config.page_param = :page
  config.per_page_param = :page_size
  config.include_total = true
end
