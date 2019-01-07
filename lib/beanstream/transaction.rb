require 'rest-client'
require 'base64'
require 'json'

module Beanstream
  class Transaction
    
    def encode(merchant_id, api_key)
      str = "#{merchant_id}:#{api_key}"
      Base64.encode64(str).gsub("\n", "")
    end
    
    def transaction_post(method, url_path, merchant_id, api_key, data={})
      enc = encode(merchant_id, api_key)
      
      path = Beanstream.api_host_url+url_path
      #puts "processing the data: #{method} #{path} #{data.to_json}"
    
      req_params = {
        :verify_ssl => OpenSSL::SSL::VERIFY_PEER,
        :ssl_ca_file => Beanstream.ssl_ca_cert,
        :timeout => Beanstream.timeout,
        :open_timeout => Beanstream.open_timeout,
        :headers => {
          :authorization => "Passcode #{enc}",
          :content_type => "application/json"
        },
        :method => method,
        :url => path,
        :payload => data.to_json
      }

      if Beanstream.sub_merchant_id
        req_params[:headers][:'Sub-Merchant-Id'] = Beanstream.sub_merchant_id
      end
      
      begin
        result = RestClient::Request.execute(req_params)
        Util.symbolize_names(JSON.parse(result))
      rescue RestClient::ExceptionWithResponse => ex
        if ex.response
          handle_api_error(ex)
        else
          raise handle_restclient_error(ex)
        end
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
      
    end
    
    def handle_api_error(ex)
      obj = JSON.parse(ex.http_body).merge("status"=> ex.http_code)
      obj = Util.symbolize_names(obj)
      
      if ex.http_code == 302
        obj[:message] = "Redirection for IOP and 3dSecure not supported by the Beanstream SDK yet. #{obj[:message]}"
      end

      obj
    end
    
    def handle_restclient_error(e)

      case e
      when RestClient::RequestTimeout
        message = "Could not connect to Beanstream"

      when RestClient::ServerBrokeConnection
        message = "The connection to the server broke before the request completed."

      when RestClient::SSLCertificateNotVerified
        message = "Could not verify Beanstream's SSL certificate. " \
          "Please make sure that your network is not intercepting certificates. "

      when SocketError
        message = "Unexpected error communicating when trying to connect to Beanstream. "

      else
        message = "Unexpected error communicating with Beanstream. "

      end

      raise APIConnectionError.new(message + "\n\n(Network error: #{e.message})")
    end
  end
  
end
