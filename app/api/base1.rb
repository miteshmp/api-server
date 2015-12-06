class Base1 < Grape::API
      version 'v1'
      
      mount UserAPI_v1
      mount AuthenticationAPI_v1
      mount DevicesAPI_v1
      mount AppAPI_v1
      mount UploadAPI_v1
      mount ExtendedAttributeAPI_v1
      mount UtilsAPI_v1
      mount RecurlyWebhooksAPI_v1
      mount DeviceModelAPI_v1
      mount DeviceTypeAPI_v1
      mount SubscriptionPlansAPI_v1
      mount Background_Tasks_api_v1
      mount RecipeAPI_v1
      mount DeviceSettingsAPI_v1
      
      # add support for swagger documnetation... this takes care of documenting grape APIs only
      add_swagger_documentation api_version: "v1",markdown: true, mount_path: '/doc',hide_documentation_path: true
    end

