class ExtendedAttributeAPI_v1 < Grape::API
	
  version 'v1', :using => :path,  :format => :json
  format :json
  formatter :json, SuccessFormatter  	 

	helpers RecurlyHelper

	resource :extended_attributes do

    desc "Get extended informations" 

      params do
        
        requires :entity_type, :type => String, :desc => "Entity name. Presently supports Device"
        optional :entity_id, :type => Integer, :desc => "Entity id."
        optional :keys, :type => String, :desc => "Comma separated list of key names"
        optional :page, :type => Integer
        optional :size, :type => Integer
        optional :filters, :type => String, :desc => "Given first preferences over above optional parameter. Specific format is required."
              {
              :notes => <<-NOTE
                Filters parameter has given first preferences over optional parameter. Developer should use syntax to get
                appropriate results. syntax should not contains escape charactor

                 syntax :-
                        name:separator:index:operator:value

                  ':' :- considered as separator in syntax
                  name :- Key Name
                  separator :- Value separator charactor. Note :-  Length must be 1
                  index : Index Number ( it should start with 1, not 0)
                  operator :- Logical operator in URL encoded form (See Metric).
                  value :- Expression value.

                  Eg:-
                  Filter syntax for Badblock:-

                  badblock:_:2:%3E:1000

                  which retunns all device which has more than 1000 badblock at partition 2.

                  Metric:-
                  1. '='  :-  %3D
                  2. '!=' :-  !%3D
                  3. '>'  :-  %3E
                  4. '<'  :-  %3C
                  5. '>=' :-  %3E%3D
                  6. '<=' :-  %3C%3D

                NOTE
              }

        
      end  
        
      get do
        
        active_user =  authenticated_user ;
        forbidden_request! unless active_user.has_authorization_to?(:read_any, ExtendedAttribute)

        unless ExtendedAttributeConfiguration::ENTITY_SUPPORT.include? params[:entity_type]
          not_found!(ENTITY_NOT_FOUND,"Entity not found : " + params[:entity_type].to_s) ;
        end

        entity_attributes = nil ;

        if ( params[:entity_type] == ExtendedAttributeConfiguration::DEVICE_ENTITY )

          if params[:filters]

            array_of_filters = params[:filters].gsub(/\'/,'').split(ExtendedAttributeConfiguration::FILTER_SEPARATOR);

            if ( array_of_filters != nil && array_of_filters.length == ExtendedAttributeConfiguration::NO_FILETER_PARAMETER)

              filter_key = array_of_filters[0];
              filter_separator = array_of_filters[1];
              filter_index = array_of_filters[2];
              filter_operator = URI.decode(array_of_filters[3]);
              filter_value = array_of_filters[4];


              if ( (  filter_key == nil || filter_separator == nil ||
                      filter_index == nil || filter_operator == nil || filter_value == nil
                    ) ||
                    ( filter_key.strip.length == 0  || filter_separator.strip.length != ExtendedAttributeConfiguration::FILTER_SEPARATOR_LENGTH ||
                      filter_index.strip.to_i == 0  || !((ExtendedAttributeConfiguration::FILTER_OPERATOR_SUPPORT).include? filter_operator ) ||
                      filter_value.length == 0
                    )
                  )

                invalid_request!(INVALID_FILTER_VALUE,ExtendedAttributeConfiguration::INVALID_FILTER_VALUE_MESSAGE);
              end

              filter_index = filter_index.strip.to_i ;
              filter_value = filter_value.strip.to_i ;

              filter_condition = "REPLACE(SUBSTRING(SUBSTRING_INDEX(extended_attributes.value, '%s', %s),LENGTH(SUBSTRING_INDEX(extended_attributes.value, '%s', %s - 1)) + 1),'%s','') %s %s" % 
                              [ filter_separator,filter_index,filter_separator,filter_index,filter_separator,filter_operator,filter_value];

              entity_attributes = ExtendedAttribute.where("entity_type = ? and extended_attributes.key = ? and #{filter_condition}",
                                  params[:entity_type],filter_key);

            else

              invalid_request!(INVALID_FILTER_SYNTAX,ExtendedAttributeConfiguration::INVALID_FILTER_SYNTAX_MESSAGE);
            end

          elsif params[:keys] && params[:entity_id]

            array_of_keys = params[:keys].split(',') ;
            entity_attributes = ExtendedAttribute.where(entity_type: params[:entity_type],entity_id: params[:entity_id],key: array_of_keys).includes(:device);
          
          elsif params[:keys]
        
            array_of_keys = params[:keys].split(',') 
            entity_attributes = ExtendedAttribute.where(entity_type: params[:entity_type],key: array_of_keys).includes(:device);
        
          elsif params[:entity_id]

             entity_attributes = ExtendedAttribute.where(entity_type: params[:entity_type],entity_id: params[:entity_id]).includes(:device);

          else
        
            entity_attributes = ExtendedAttribute.where(entity_type: params[:entity_type]).includes(:device);
        
          end 

          present entity_attributes.paginate(:page => params[:page], :per_page => params[:size]), with: ExtendedAttribute::Entity, type: :device
      
        end

      end  
  
  end	
  # complete :- "resource"
end	