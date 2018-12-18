module Beanstream
  class BankAPI

    attr_accessor :default_query_string
    def initialize
      @default_query_string = {
        merchantId: Beanstream.merchant_id,
        passCode: Beanstream.profiles_api_key,
        serviceVersion: "1.0",
        subMerchantId: Beanstream.sub_merchant_id,
      }

    end

    

    def create_profile(profile)
      query_string = set_query_string(profile).merge(@default_query_string)
      query_string[:operationType] = 'N'
      post('POST', '/scripts/payment_profile.asp', query_string)
    end

    def update_profile(profile)
      query_string = set_query_string(profile).merge(@default_query_string)
      query_string[:operationType] = 'M'
      post('POST', '/scripts/payment_profile.asp', query_string)
    end

    def get_profile(profile)
      query_string = set_query_string(profile).merge(@default_query_string)
      query_string[:operationType] = 'Q'
      post('POST', '/scripts/payment_profile.asp', query_string)
    end


    private

    def set_query_string(params)
      query_string = {}

      { customer_code: :customerCode,
        bank_account_type: :bankAccountType,
        account_holder: :bankAccountHolder,
        institution_number: :institutionNumber,
        routing_number: :routingNumber,
        branch_number: :branchNumber,
        account_number: :accountNumber,
        billing_contact: :ordName,
        billing_email: :ordEmailAddress,
        billing_phone: :ordPhoneNumber,
        billing_address: :ordAddress1,
        billing_city: :ordCity,
        billing_postal: :ordPostalCode,
        billing_province: :ordProvince,
        billing_country: :ordCountry,
      }.each do |k,v|
        query_string[v] = params[k] if params[k]
      end

      query_string
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
        response = Hash.from_xml(result)['response']

        response['responseCode'].to_i == 1 ? response : raise(handle_api_error(response))
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
      
    end    

    def handle_api_error(ex)
      begin
        obj = Util.symbolize_names(ex)
        code = obj[:responseCode]
        message = obj[:responseMessage]
        "Error #{code}: #{message} #{ex}"
      rescue JSON::ParserError
        "Error parsing xml error message"
      end
    end

    def handle_restclient_error(e)
      case e
      when RestClient::RequestTimeout
        message = "Could not connect to Beanstream"
      when RestClient::ServerBrokeConnection
        message = "The connection to the server broke before the request completed."
      when RestClient::SSLCertificateNotVerified
        message = "Could not verify Beanstream's SSL certificate. Please make sure that your network is not intercepting certificates. "
      when SocketError
        message = "Unexpected error communicating when trying to connect to Beanstream. "
      else
        message = "Unexpected error communicating with Beanstream. "
      end
      raise message + "\n\nNetwork error: #{e.message}"
    end
  end
end