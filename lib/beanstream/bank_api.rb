module Beanstream
  class BankAPI

    attr_accessor :default_query_string

    MESSAGES = {
      1 => 'Invalid bank number',
      2 => 'Invalid branch number',
      3 => 'Invalid account number',
      4 => 'Invalid transaction amount',
      5 => 'Reference number too long',
      6 => 'Invalid due date',
      7 => 'Due date out of valid date range',
      8 => 'Customer name truncated to 32 characters',
      9 => 'Customer name missing',
      10 => 'Duplicate transaction matching bank account',
      11 => 'Zero, negative or non-numeric amount',
      12 => 'Invalid bank and/or branch number',
      13 => 'Payee/drawee name cannot be spaces',
      14 => 'Invalid payment code',
      15 => 'Invalid transaction type',
      16 => 'Account Closed',
      17 => 'NSF – Debit declined due to insufficient funds.',
      18 => 'Transaction rejected by Bank',
      19 => 'Invalid bank, branch, or account number',
      20 => 'Refused by payor',
      21 => 'Funds not cleared',
      22 => 'Account Frozen',
      23 => 'Payment Stopped',
      24 => 'Transaction Cancelled',
      25 => 'Cannot Trace',
      26 => 'Incorrect Payor/Payee Name',
      27 => 'Payor/Payee Deceased',
      28 => 'Invalid transit routing number',
      29 => 'Invalid Account Type',
      30 => 'Transaction type not permitted',
      31 => 'No Checking Privileges',
      33 => 'Edit Reject',
      35 => 'Reserved Return Code',
      36 => 'Payment Recalled',
      38 => 'Not in accordance with agreement – Personal',
      39 => 'Agreement revoked – Personal',
      40 => 'No pre-notification – Personal',
      41 => 'Not in accordance with agreement – Business',
      42 => 'Agreement revoked – Business',
      43 => 'No pre-notification – Business',
      44 => 'Customer Initiated Return Credit Only',
      45 => 'Currency/Account Mismatch',
      46 => 'No Debit Allowed',
      47 => 'Interbank – Returned Item',
      48 => 'Routing as entered, account modified',
      49 => 'Routing as entered, repair of account unknown',
      50 => 'Routing as entered, account unknown',
      51 => 'Routing number modified, account as entered',
      52 => 'Routing number modified, account modified',
      53 => 'Routing number modified, repair of account unknown',
      54 => 'Routing number modified, account unknown',
      55 => 'ACH Unavailable for account',
      56 => 'Customer code invalid/missing payment info',
      58 => 'Profile status is closed or disabled',
      59 => 'Invalid SEC code',
      60 => 'Invalid Account Identifier',
      61 => 'Invalid Account Identifier',
      62 => 'Reference Number is Missing',
      63 => 'Invalid Customer Country Code',
      64 => 'Invalid Bank Country Code',
      65 => 'Invalid Bank Name',
      66 => 'Bank Name is Missing',
      67 => 'Addendum not allowed, too long, or has invalid characters',
      68 => 'Invalid Bank Descriptor',
      69 => 'Invalid Customer Name',
      70 => 'Transaction rejected - contact support',
      71 => 'Refund Request by End Customer',
      72 => 'Blocked due to a Notice of Change'
    }

    def initialize
      @default_query_string = {
        merchantId: Beanstream.merchant_id,
        passCode: Beanstream.profiles_api_key,
        serviceVersion: "1.0",
        subMerchantId: Beanstream.sub_merchant_id,
      }
    end

    def self.message(id) MESSAGES[id]  end

    def create_profile(profile)
      query_string = set_query_string(profile.symbolize_keys).merge(@default_query_string)
      query_string[:operationType] = 'N'
      query_string.delete(:subMerchantId)
      post('/scripts/payment_profile.asp', query_string)
    end

    def update_profile(profile)
      query_string = set_query_string(profile.symbolize_keys).merge(@default_query_string)
      query_string[:operationType] = 'M'
      post('/scripts/payment_profile.asp', query_string)
    end

    def get_profile(profile)
      query_string = set_query_string(profile.symbolize_keys).merge(@default_query_string)
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

    def batch_report(sub_merchant_id, batch_id, type, from="", to="")
      body = %Q{<?xml version="1.0" encoding="utf-8"?>
        <request>
          <rptVersion>2.0</rptVersion>
          <serviceName>BatchPayments#{type}</serviceName>
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

    def self.format_transaction_as_csv(type, params)
      if type == 'EFT'
        ['E'] + [:transaction_type, :institution_number, :transit_number, :account_number, :amount, :reference_number, :recipient_name, :customer_code, :description].map { |k| params[k]}
      elsif type == 'ACH'
        ['A'] + [:transaction_type, :routing_number, :account_number, :account_code, :amount, :reference_number, :recipient_name, :customer_code, :description].map { |k| params[k]}
      end
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

        normalize_response(response)
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
    end    

    def normalize_response(response)
      if response["responseCode"]
        response["code"] = response.delete "responseCode"
        response["message"] = response.delete "responseMessage"
      end
      response["code"] = response["code"].to_i
      response.symbolize_keys
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