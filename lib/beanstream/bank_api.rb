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
      post('/scripts/payment_profile.asp', query_string)
    end

    def update_profile(profile)
      query_string = set_query_string(profile).merge(@default_query_string)
      query_string[:operationType] = 'M'
      post('/scripts/payment_profile.asp', query_string)
    end

    def get_profile(profile)
      query_string = set_query_string(profile).merge(@default_query_string)
      query_string[:operationType] = 'Q'
      post('/scripts/payment_profile.asp', query_string)
    end

    def batch_payments(sub_merchant_id, transactions)
      content = ""
      transactions.each do |row|
        content += "#{row.join(",")}\r\n"
      end
      multiparty = Multiparty.new
      multiparty[:criteria] = { content_type: 'application/json', content: %Q({"process_now": 1, "sub_merchant_id": "#{sub_merchant_id}"}) }
      multiparty[:data] = { filename: "merchant_#{sub_merchant_id}.txt", content_type: 'text/plain', content: content}

      headers = {"FileType" => "STD"}
      headers.merge!(Hash[*multiparty.header.strip.split(': ')])
      body = multiparty.body + "\r\n"
      post("#{Beanstream.api_base_url()}/batchpayments", nil, headers, body)
    end

    def batch_report(sub_merchant_id, batch_id, from, to)
      body = %Q{<?xml version="1.0" encoding="utf-8"?>
        <request>
          <rptVersion>2.0</rptVersion>
          <serviceName>BatchPaymentsACH</serviceName>
          <merchantId>#{Beanstream.merchant_id}</merchantId>
          <subMerchantId>#{sub_merchant_id}</subMerchantId>
          <sessionSource>external</sessionSource >
          <passCode>#{Beanstream.reporting_api_key}</passCode>
          <rptFormat>JSON</rptFormat>
          <rptFromDateTime>#{from}</rptFromDateTime>
          <rptToDateTime>#{to}</rptToDateTime>
          <rptFilterBy1>batch_id</rptFilterBy1>
          <rptOperationType1>EQ</rptOperationType1>
          <rptFilterValue1>#{batch_id}</rptFilterValue1>
        </request>
      }
      post('/scripts/reporting/report.aspx', nil, {"Content-Type" => "application/xml"}, body)
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

    def post(url_path, query_string, headers = {}, body = nil)
      headers ||= {}
      enc = encode(Beanstream.merchant_id, Beanstream.batch_api_key)

      uri = Beanstream.api_host_url+url_path
      uri += '?' + query_string.to_query if query_string
      url = URI(uri)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.ca_file = Beanstream.ssl_ca_cert
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      # http.set_debug_output $stderr
      request = Net::HTTP::Post.new(url)
      
      headers.merge!({ Authorization: "Passcode #{enc}" })
      headers.each { |k,v| request[k] = v }
      request.body = body

      begin
        result = http.request(request)
        response = Hash.from_xml(result.read_body) rescue nil
        response ||= JSON.parse(result.read_body)
        response = response["response"] if response["response"]
        code = response['responseCode'] || response['code']
        message = response['responseMessage'] || response['message']
        code.to_i == 1 ? normalize_response(response) : raise(handle_api_error(code, message, response))
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
    end    

    def normalize_response(response)
      if response["responseCode"]
        response["code"] = response.delete "responseCode"
        response["message"] = response.delete "responseMessage"
      end
      response
    end

    def handle_api_error(code, message, ex)
      begin
        "Error #{code}: #{message} #{normalize_response(ex)}"
      rescue JSON::ParserError
        "Error parsing error message"
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