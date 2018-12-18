# Bambora's Ruby SDK

Integration with Bambora’s payments gateway is a simple, flexible solution.

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
Create a profile with bank info:
```ruby
Beanstream::BankAPI.new().create_profile({
  operation: "N",
  bank_account_type: "PC",
  accoiunt_holder: "John Doe",
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

Get a profile: 
```ruby
Beanstrea.ProfilesAPI().get_profile(profile_id)
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
