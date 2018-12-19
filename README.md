# Bambora's Ruby SDK

You can choose between a straightforward payment requiring very few parameters; or, you can customize a feature-rich integration.

To assist as a centralized record of all your sales, we also accept cash and cheque transactions.

For very detailed information on the Payments API, look at the Bambora [developer portal](https://dev.na.bambora.com/docs/references/payment_SDKs/take_payments/).


# TLS 1.2 support
For testing instructions with our TLS1.2-only server, please refer to our [developer portal](https://dev.na.bambora.com/docs/references/payment_SDKs/support_tls12/#ruby-sdk)


# Setup
To install the SDK you just need to simply install the gem file:
```
gem install beanstream --pre
```

# Profiles
Create a profile with a raw credit card:

```ruby
Beanstream.sub_merchant_id = "XXXXXXXX"
Beanstream.merchant_id = "XXXXXXXX"
Beanstream.profiles_api_key = "XXXXXXXXXXXXXXXXXXXXX"

body = {
  "card": {
    "name": "Jon Doe",
    "number": "4030000010001234",
    "expiry_month": "02",
    "expiry_year": "18",
    "cvd": "123"
  },
  "billing": {
      "name": "Jon Doe",
         "address_line1": "123 Main St.",
         "address_line2": "",
         "city": "victoria",
         "province": "bc",
         "country": "ca",
         "postal_code": "V9B3Z4",
  }
}

Beanstream.ProfilesAPI().create_profile(profile)
```

Get a profile:

```ruby
Beanstrea.ProfilesAPI().get_profile(profile_id)
```


Make CC payment using profile:

```ruby
Beanstream.sub_merchant_id = "XXXXXXXX"
Beanstream.merchant_id = "XXXXXXXX"
Beanstream.profiles_api_key = "XXXXXXXXXXXXXXXXXXXXX"
Beanstream.payments_api_key = "XXXXXXXXXXXXXXXXXXXXX"

profile = {
  "amount": 100.00,
  "payment_method":"payment_profile",
  "payment_profile": { 
    "customer_code": "XXXXXXXXXXXXXXXXXXXXX", 
    "card_id": "1",
    "complete": true
  }
}

Beanstream::PaymentsAPI.new.make_payment(profile)

Response: 

{"id"=>"10000006", "authorizing_merchant_id"=>XXXXXXXX, "approved"=>"1", "message_id"=>"1", "message"=>"Approved", "auth_code"=>"TEST", "created"=>"2018-12-17T20:51:05", "order_number"=>"10000006", "type"=>"P", "payment_method"=>"CC", "risk_score"=>0.0, "amount"=>100.0, "custom"=>{"ref1"=>"", "ref2"=>"", "ref3"=>"", "ref4"=>"", "ref5"=>""}, "card"=>{"card_type"=>"VI", "last_four"=>"1234", "address_match"=>0, "postal_result"=>0, "avs_result"=>"0", "cvd_result"=>"2", "avs"=>{"id"=>"N", "message"=>"Street address and Postal/ZIP do not match.", "processed"=>true}}, "links"=>[{"rel"=>"void", "href"=>"https://www.beanstream.com/api/v1/payments/10000006/void", "method"=>"POST"}, {"rel"=>"return", "href"=>"https://www.beanstream.com/api/v1/payments/10000006/returns", "method"=>"POST"}]}

```

# Bank API (legacy)

### Create profile:

```ruby
Beanstream.merchant_id = "XXXXXXXX"
Beanstream.sub_merchant_id = "XXXXXXXX"
Beanstream.profiles_api_key = "XXXXXXXXXXXXXXXXXXXXX"

Beanstream::BankAPI.new().create_profile({
  bank_account_type: "PC",
  account_holder: "John Doe",
  institution_number: 123,
  routing_number: 123456789,
  branch_number: 12345,
  account_number: 123456789,
  billing_contact: "Rosanna+Sylvester",
  billing_email: "joe@mydomain.com",
  billing_phone: "2504722326",
  billing_address: "123+Main+Street",
  billing_city: "New York",
  billing_postal: "10027",
  billing_province: "NY",
  billing_country: "US  ",
})
```

**Response:**

```
{
  "customerCode"=>"XXXXXXXXXXXXXXXXXXX",
  "responseCode"=>"1",
  "responseMessage"=>"Operation Successful",
  "trnOrderNumber"=>nil,
  "trnCardNumber"=>nil,
  "cardType"=>nil,
  "httpStatusCode"=>"200",
  "category"=>"1"
}
```

### Update profile:

```ruby
Beanstream.merchant_id = "XXXXXXXX"
Beanstream.sub_merchant_id = "XXXXXXXX"
Beanstream.profiles_api_key = "XXXXXXXXXXXXXXXXXXXXX"

Beanstream::BankAPI.new().update_profile({
  customer_code: 'XXXXXXXXXXXXXXXXXXXXXXXXXX',
  bank_account_type: "PC",
  account_holder: "John Doe",
  institution_number: 123,
  routing_number: 123456789,
  branch_number: 12345,
  account_number: 123456789,
  billing_contact: "Rosanna+Sylvester",
  billing_email: "joe@mydomain.com",
  billing_phone: "2504722326",
  billing_address: "123+Main+Street",
  billing_city: "New York",
  billing_postal: "10027",
  billing_province: "NY",
  billing_country: "US  ",
})
```

**Response:**

```
{
  "customerCode"=>"XXXXXXXXXXXXXXXXXXX",
  "responseCode"=>"1",
  "responseMessage"=>"Operation Successful",
  "trnOrderNumber"=>nil,
  "trnCardNumber"=>nil,
  "cardType"=>nil,
  "httpStatusCode"=>"200",
  "category"=>"1"
}
```

### Get profile
```ruby
Beanstream.merchant_id = "XXXXXXXX"
Beanstream.sub_merchant_id = "XXXXXXXX"
Beanstream.profiles_api_key = "XXXXXXXXXXXXXXXXXXXXX"

result = Beanstream::BankAPI.new().get_profile({
  customer_code: 'XXXXXXXXXXXXXXXXXXXXXXXXXX'
})
```

**Response:**

```
{
  "customerCode"=>"XXXXXXXXXXXXXXXXXXXXXXXXXX",
  "customerLanguage"=>"en",
  "responseCode"=>"1",
  "responseMessage"=>"Operation Successful",
  "status"=>"A",
  "ordName"=>"Rosanna+Sylvester",
  "ordAddress1"=>"123+Main+Street",
  "ordAddress2"=>nil,
  "ordCity"=>"New York",
  "ordProvince"=>"NY",
  "ordCountry"=>"US",
  "ordPostalCode"=>"10027",
  "ordEmailAddress"=>"joe@mydomain.com",
  "ordPhoneNumber"=>"2504722326",
  "profileGroup"=>nil,
  "velocityGroup"=>nil,
  "accountRef"=>nil,
  "trnCardNumber"=>nil,
  "trnCardExpiry"=>nil,
  "bankAccountType"=>"PC",
  "lastCCTransDate"=>"1/1/1900",
  "paymentModifiedDate"=>"1/1/1900"
}
```

### Batch payments
```ruby
transactions = [
  ["A","C",nil,nil,nil,10000,7777,nil,"XXXXXXXXXXXXX","dynamic descriptor"],
  ["A","C",nil,nil,nil,10000,7777,nil,"XXXXXXXXXXXXX","dynamic descriptor"]
]
Beanstream::BankAPI.new().batch_payments(Beanstream.sub_merchant_id, transactions)
```

**Response:**

```
{
  "code"=>1,
  "message"=>"File successfully received",
  "batch_id"=>10000031,
  "process_date"=>"20181219",
  "process_time_zone"=>"GMT-08:00",
  "batch_mode"=>"test"
}
```

### Batch report

```ruby
Beanstream.reporting_api_key = "XXXXXXXXXXXXXXXXXXXX"

Beanstream::BankAPI.new().batch_report(
  Beanstream.sub_merchant_id,
  10000036,
  "2018-11-11 00:00:00",
  "2018-12-31 00:00:00"
)
```

**Response:**

```
{
  "version"=>"1.0",
  "code"=>1,
  "message"=>"Report generated",
  "records"=>{
    "total"=>0
  },
  "record"=>[
    {
      "rowId"=>0,
      "merchantId"=>XXXXXXXXXX,
      "batchId"=>10000036,
      "transId"=>25,
      "itemNumber"=>1,
      "payeeName"=>"John Doe",
      "reference"=>"7777",
      "operationType"=>"C",
      "amount"=>10000,
      "bankAccountType"=>"PC",
      "secCode"=>"   ",
      "stateId"=>2,
      "stateName"=>"Scheduled",
      "statusId"=>3,
      "statusName"=>"Transaction Warning",
      "bankDescriptor"=>"dynamic descriptor",
      "messageId"=>"10",
      "customerCode"=>"XXXXXXXXXXXXXXXXXXXX",
      "settlementDate"=>"2018-12-20",
      "returnedDate"=>"",
      "eftId"=>0,
      "nocDate"=>"",
      "nocAccountType"=>"",
      "nocRoutingNumber"=>"",
      "nocAccountNumber"=>""
    },
    {
      "rowId"=>0,
      "merchantId"=>XXXXXXXXXXX,
      "batchId"=>10000036,
      "transId"=>26,
      "itemNumber"=>2,
      "payeeName"=>"John Doe",
      "reference"=>"7778",
      "operationType"=>"C",
      "amount"=>10000,
      "bankAccountType"=>"PC",
      "secCode"=>"   ",
      "stateId"=>2,
      "stateName"=>"Scheduled",
      "statusId"=>3,
      "statusName"=>"Transaction Warning",
      "bankDescriptor"=>"dynamic descriptor",
      "messageId"=>"10",
      "customerCode"=>"XXXXXXXXXXXXXXXXXXXX",
      "settlementDate"=>"2018-12-20",
      "returnedDate"=>"",
      "eftId"=>0,
      "nocDate"=>"",
      "nocAccountType"=>"",
      "nocRoutingNumber"=>"",
      "nocAccountNumber"=>""
    }
  ]
}
```

# Code Sample
Take a credit card Payment:

```ruby
begin
  result = Beanstream.PaymentsAPI.make_payment(
  {
    :order_number => PaymentsAPI.generateRandomOrderId("test"),
    :amount => 100,
    :payment_method => PaymentMethods::CARD,
    :card => {
      :name => "Mr. Card Testerson",
      :number => "4030000010001234",
      :expiry_month => "07",
      :expiry_year => "22",
      :cvd => "123",
      :complete => true
    }
  })
  puts "Success! TransactionID: #{result['id']}"
  
rescue BeanstreamException => ex
  puts "Exception: #{ex.user_facing_message}"
end
```


# Reporting Issues
Found a bug or want a feature improvement? Create a new Issue here on the github page.
