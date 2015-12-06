module SuccessFormatter

  def self.call object, env
    {
      :status => 200,
      :message => 'Success!',
      :data => object
    }.to_json
  end

end

module ErrorFormatter

  def self.call message, backtrace, options, env
    # This uses convention that a error! with a Hash param is a jsend "fail", otherwise we present an "error"
    if message.is_a?(Hash)
      message.to_json
    else
    {
      :status => 400,
      :code => 400,
      :message => message,
      :more_info => Settings.error_docs_url %  400
    }.to_json
    end
  end

end
