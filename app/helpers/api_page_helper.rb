module ApiPageHelper
  PAGINATE_OPTIONS = {
    :default_page_size => 10
  }
  PAGINATE_PARAMS = [ "page", "offset", "size" ]
  def paginate(coll, options = {})
    options = PAGINATE_OPTIONS.merge(options)
    if params[:page]
      page = params[:page].to_i
      size = (params[:size] || options[:default_page_size]).to_i
      error!("Invalid page: #{page}", 400) if page < 0
      error!("Invalid page size: #{size}", 400) if size <= 0
      if coll.respond_to?(:page)
        coll = coll.page(page).per(size)
      elsif coll.respond_to?(:skip) and coll.respond_to?(:limit)
        coll = coll.skip(size * (page - 1)).limit(size)
      elsif coll.is_a?(Array)
        coll = coll[((page - 1) * size)...(page * size)]
      else
        error!("Cannot paginate #{coll.class.name}", 500)
      end
    else
      if params[:offset]
        offset = params[:offset].to_i
        error!("Invalid offset: #{offset}", 400) if offset < 0
        
        if coll.respond_to?(:skip)          
          coll = coll.skip(offset)
        elsif coll.is_a?(Array)          
          coll = coll[offset..-1]
        else
          error!("Cannot offset #{coll.class.name}", 500)
        end
      end
      
      limit = nil
      if params[:size]
        limit = params[:size].to_i
        error!("Invalid limit: #{limit}", 400) if limit <= 0
        limit = [ limit, options[:max_size] ].min if options[:max_size]
      elsif options[:max_size]
        limit = options[:max_size].to_i
      end
      if limit
        if coll.respond_to?(:limit)
          coll = coll.limit(limit)
        elsif coll.is_a?(Array)
          coll = coll[0..limit - 1]
        else
          error!("Cannot limit #{coll.class.name}", 500)
        end
      end
    end
    (coll.is_a?(Module) and coll.respond_to?(:all)) ? coll.all : coll
  end
end