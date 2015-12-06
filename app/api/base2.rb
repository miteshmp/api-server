class Base2 < Grape::API
      version 'v2'
      # mount the APIs that we want to expose
      mount DevicesAPI_v2
      
      # add support for swagger documnetation... this takes care of documenting grape APIs only
      add_swagger_documentation api_version: "v2",markdown: true, mount_path: '/doc',hide_documentation_path: true


end