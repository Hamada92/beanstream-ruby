module Beanstream
  class BankAPI

    def create_profile(profile)

      query_string = {
        merchantId: Beanstream.merchant_id,
        passCode: Beanstream.profiles_api_key,
        serviceVersion: "1.0",
        subMerchantId: Beanstream.sub_merchant_id,
        operationType: 'N'
      }

      # //customerCode:{{profileId}}
      query_string[:bankAccountType] = profile[:bank_account_type]
      query_string[:bankAccountHolder] = profile[:accoiunt_holder]
      query_string[:institutionNumber] = profile[:institution_number]
      query_string[:routingNumber] = profile[:routing_number]
      query_string[:branchNumber] = profile[:branch_number]
      query_string[:accountNumber] = profile[:account_number]
      query_string[:ordName] = profile[:billing_contact]
      query_string[:ordEmailAddress] = profile[:billing_email]
      query_string[:ordPhoneNumber] = profile[:billing_phone]
      query_string[:ordAddress1] = profile[:billing_address]
      query_string[:ordCity] = profile[:billing_city]
      query_string[:ordPostalCode] = profile[:billing_postal]
      query_string[:ordProvince] = profile[:billing_province]
      query_string[:ordCountry] = profile[:billing_country]


      post('POST', '/scripts/payment_profile.asp', query_string)
    end

    def encode(merchant_id, api_key)
      str = "#{merchant_id}:#{api_key}"
      Base64.encode64(str).gsub("\n", "")
    end

    def post(method, url_path, query_string, data={})
      enc = encode(Beanstream.merchant_id, Beanstream.batch_api_key)
      
      path = Beanstream.api_host_url+url_path
      path += '?' + query_string.to_query if query_string

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
        :payload => <<-DATA
        DATA
      }
      
      begin
        result = RestClient::Request.execute(req_params)
        return Hash.from_xml(result)['response']
      rescue RestClient::ExceptionWithResponse => ex
        if ex.response
          raise handle_api_error(ex)
        else
          raise handle_restclient_error(ex)
        end
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
      
    end    


    def handle_api_error(ex)
      #puts "error: #{ex}"
      
      http_status_code = ex.http_code
      message = ex.message
      code = 0
      category = 0
      
      begin
        obj =  Hash.from_xml(ex.http_body)['response']
        obj = Util.symbolize_names(obj)
        code = obj[:responseCode]
        category = obj[:category]
        message = obj[:message]
      rescue JSON::ParserError
        puts "Error parsing xml error message"
      end
      
      if http_status_code == 302
        raise InvalidRequestException.new(code, category, "Redirection for IOP and 3dSecure not supported by the Beanstream SDK yet. #{message}", http_status_code)
      elsif http_status_code == 400
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code == 401
        raise UnauthorizedException.new(code, category, message, http_status_code)
      elsif code == 402
        raise BusinessRuleException.new(code, category, message, http_status_code)
      elsif code == 403
        raise ForbiddenException.new(code, category, message, http_status_code)
      elsif code == 405
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code == 415
        raise InvalidRequestException.new(code, category, message, http_status_code)
      elsif code >= 500
        raise InternalServerException.new(code, category, message, http_status_code)
      else
        raise BeanstreamException.new(code, category, message, http_status_code)
      end
    end
  end
end